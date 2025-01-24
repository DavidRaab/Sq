package Sq;
use 5.036;
our $VERSION = '0.007';
use Carp ();
use Scalar::Util ();
# This variable is by default 0 and will be set to 1 when user does
#
#     use Sq sig => 1
#
# Then all other modules that use Sq::Exporter will load it's defined
# signature file.
our $LOAD_SIGNATURE = 0;
# All functions that are Exported
our @EXPORT = (
    qw(sq call key assign seq new),
    qw(is_num is_str is_array is_hash is_seq is_opt is_result is_sub is_regex is_ref),
    qw(fn multi with_dispatch type_cond),
    qw(id fst snd),
    qw(by_num by_str by_stri),
    qw(array hash record),
    qw(Str),
    Some    => sub { \&Option::Some           },
    None    => sub { \&Option::None           },
    Ok      => sub { \&Result::Ok             },
    Err     => sub { \&Result::Err            },
    lazy    => sub { \&Sq::Core::Lazy::lazy   },
    equal   => sub { \&Sq::Equality::equal    },
    dump    => sub { \&Sq::Dump::dump         },
    dumps   => sub { \&Sq::Dump::dumps        },
    type    => sub { \&Sq::Type::type         },
    is_type => sub { \&Sq::Type::t_valid      },
    static  => sub { \&Sq::Reflection::static },
);
my $export_funcs;
my $first_load = 1;
sub import {
    my ( $own, @requested ) = @_;
    my ( $pkg ) = caller;

    # Load some modules on import()
    if ( $first_load ) {
        require Sq::Core::Str;
        require Sq::Type;
        require Sq::Fs;
        require Sq::Io;
        $first_load = 0;
    }

    no strict 'refs'; ## no critic
    # Build cache for easier exporting
    if ( !defined $export_funcs ) {
        my $idx = 0;
        while ( $idx < @EXPORT ) {
            my $func = $EXPORT[$idx];
            my $next = $EXPORT[$idx+1];

            if ( ref $next eq 'CODE' ) {
                $export_funcs->{$func} = $next;
                $idx += 2;
            }
            elsif ( $func eq '-sig' ) {
                $idx += 2;
            }
            else {
                $export_funcs->{$func} = sub { *{$func}{CODE} };
                $idx += 1;
            }
        }
    }

    # Build new @req with options removed
    my ($idx, @req, $value) = (0);
    while ( $idx < @requested ) {
        $value = $requested[$idx];
        if ( $value eq '-sig' ) {
            $LOAD_SIGNATURE = 1 if $requested[$idx+1];
            $idx += 2;
        }
        else {
            push @req, $value;
            $idx += 1;
        }
    }

    # Load signature if requested
    if ( $LOAD_SIGNATURE ) {
        require Sq::Sig;
    }

    # Export only requested
    if ( @req > 0 ) {
        my $fn;
        for my $request ( @req ) {
            $fn = $export_funcs->{$request};
            Carp::croak "Export Func '$request' does not exists"
                if !defined $fn;
            *{"$pkg\::$request"} = $fn->();
            $idx++;
        }
    }
    # Export ALL
    else {
        for my ($name, $fn) ( %$export_funcs ) {
            *{"$pkg\::$name"} = $fn->();
        }
    }
}

# Load Core
use Sq::Reflection;
use Sq::Core;

# Load Collections
use Sq::Collections::Array;
use Sq::Collections::Hash;
use Sq::Collections::Seq;
use Sq::Collections::Queue;
use Sq::Collections::List;
use Sq::Collections::Heap;

# Load other basic functionality
use Sq::Dump;
use Sq::Equality;

# Access to submodules
sub io($)    { 'Sq::Io'    }
sub fs($)    { 'Sq::Fs'    }
sub math($)  {
    if ( !exists $INC{'Sq/Math.pm'} ) {
        require Sq::Math;
        Sq::Math->load_signature();
    }
    return 'Sq::Math';
}
sub fmt($)   {
    if ( !exists $INC{'Sq/Fmt.pm'} ) {
        require Sq::Fmt;
        Sq::Fmt->load_signature();
    }
    return 'Sq::Fmt';
}
sub bench($) { require Sq::Bench; return 'Sq::Bench' }

# Like a Str module
sub Str :prototype() { return 'Sq::Core::Str' }

# Important functions used in FP code. So adding them.
sub id  :prototype($) { return $_[0]    }
sub fst :prototype($) { return $_[0][0] }
sub snd :prototype($) { return $_[0][1] }

# a helper to create a function for selecting a hash-key
sub key :prototype($) {
    state %cache;
    my $name = $_[0];

    # return cached sub
    my $func = $cache{$name};
    return $func if defined $func;

    # otherwise create/store new sub
    $func = sub($hash) { return $hash->{$name} };
    $cache{$name} = $func;
    return $func;
}

# returns a function that calls $method with its arguments on an object
{
    no strict 'refs'; ## no critic
    sub call($method, @args) {
        return sub($obj) {
            my $type = ref $obj;
            if    ( $type eq 'ARRAY' ) { return &{"Array::$method"}($obj,@args) }
            elsif ( $type eq 'HASH'  ) { return &{"Hash::$method" }($obj,@args) }
            else                       { return $obj->$method(@args)            }
        };
    }
}

# allows writing a code block to create a value
sub assign :prototype(&) {
    return $_[0]->();
}

### Type-Checking functions

sub is_str :prototype($) {
    return ref $_[0] eq '' ? 1 : 0;
}

# This makes is_num() a direct copy of looks_like_number. So it is called
# without any overhead. When `is_num` is exported than those are also copies
# of this one. So calling `is_num` is the same speed as calling
# looks_like_number().
{
    no warnings 'once';
    *is_num = \&Scalar::Util::looks_like_number;
}

sub is_array :prototype($) {
    my $type = ref $_[0];
    return 1 if $type eq 'Array' || $type eq 'ARRAY';
    return 0;
}

sub is_hash :prototype($) {
    my $type = ref $_[0];
    return 1 if $type eq 'Hash' || $type eq 'HASH';
    return 0;
}

sub is_seq    :prototype($)  { return ref $_[0] eq 'Seq'    ? 1 : 0 }
sub is_opt    :prototype($)  { return ref $_[0] eq 'Option' ? 1 : 0 }
sub is_result :prototype($)  { return ref $_[0] eq 'Result' ? 1 : 0 }
sub is_ref    :prototype($$) { return ref $_[1] eq $_[0]    ? 1 : 0 }
sub is_regex  :prototype($)  { return ref $_[0] eq 'Regexp' ? 1 : 0 }
sub is_sub    :prototype($)  { return ref $_[0] eq 'CODE'   ? 1 : 0 }

### Comparision Functions

sub by_num :prototype() {
    state $fn = sub($x,$y) { $x <=> $y };
    return $fn;
}

sub by_str :prototype() {
    state $fn = sub($x,$y) { $x cmp $y };
    return $fn;
}

sub by_stri :prototype() {
    state $fn = sub($x,$y) { fc($x) cmp fc($y) };
    return $fn;
}

# recursively traverse a data-structure and add Array/Hash blessings
sub sq :prototype($);
sub sq :prototype($) {
    my ( $any ) = @_;
    my $type = ref $any;

    # Add Array/Hash blessing to current ref
    CORE::bless($any, 'Array'), $type = 'Array' if $type eq 'ARRAY';
    CORE::bless($any, 'Hash'),  $type = 'Hash'  if $type eq 'HASH';

    # recursively go through each data-structure
    if ( $type eq 'Hash' ) {
        for my $value ( values %$any ) {
            sq $value;
        }
    }
    elsif ( $type eq 'Array' ) {
        for my $x ( @$any ) { sq $x }
    }
    elsif ( $type eq 'Option' ) {
        for my $x ( @$any ) { sq $x }
    }
    elsif ( $type eq 'Result' ) {
        sq $any->[1];
    }
    else {
        # Do nothing for unknown type
    }
    return $any;
}

# allows writing "seq { 1,2,3 }" for a sequence
#
# actually {} is a code-reference and it can be any code in there. Whatever
# it returns in list context becomes part of a sequence.
sub seq :prototype(&) {
    my @data = $_[0]->();
    return bless(sub {
        my $abort = 0;
        my $idx   = 0;
        my $value;
        return sub {
            return undef if $abort;
            $value = $data[$idx++];
            return $value if defined $value;
            $abort = 1;
            return undef;
        }
    }, 'Seq');
}

# try out a new() function
# the idea is to have a single function that then does a dispatch. This also
# could be a dispatch of a type. Somehow reminds me on Haskell, but also
# basically shows what object-orientation is. It's a dispatch on a single
# type that usually happens at runtime.
#
# Why Haskell? For example I could use the same mechanism for fold()
#
# fold $array
# fold $seq
# fold $hash
#
# and it would dispatch to Array::fold, Seq::fold or Hash::fold depending
# on the type of it's first argument. But i just can write `fold`. This
# costs more runtime, as the function must be searched in the dispatch-table
# exactly like in OO. But it gives more flexibility. For example switching
# to Seq from Array would not break the code. You don't need to manually
# change from Array::fold to Seq::fold. In that regards it has the same benefits
# as calling a method $obj->fold(). Here i also don't care for the type,
# and the dispatch is done for me. Same principle. Only difference is
# that it is a function-call instead of a method. Theoretically can be extended
# like in Dump/Equality so someone can add new things to it.
#
# I could make this the default for initialization and only use functional-style.
# An idea i am thinking of. The benefit of just the functional-style would be
# that all blessings could be deleted from the whole code. Making the whole
# system a lot faster.
#
# And for the fools:
#   my $array = new Array => (1,2,3)
#
# looks object-oriented! but without Perl syntactic sugar it is just:
#
# my $array = new('Array',1,2,3);
#
# but here is an interesting question. Why do you want to write the left,
# when you just can write the right?
#
# LEFT                       RIGHT
# new Array => (1,2,3)       [1,2,3]
# new Seq   => (1,2,3)       seq { 1,2,3 }
# new Hash  => (foo => 1)    { foo => 1 }
#
# Even Lisp-style would be better IMHO
#
# (list 1 2 3)
# (seq  1 2 3)
# (hash foo 1)
sub new($what, @args) {
    state %new = (
        Array => sub { Array->new(@_) },
        Hash  => sub { Hash ->new(@_) },
        Seq   => sub { Seq  ->new(@_) },
        Queue => sub { Queue->new(@_) },
        List  => sub { List ->new(@_) },
        Heap  => sub { Heap ->new(@_) },
    );
    my $fn = $new{$what};
    if ( defined $fn ) {
        return $fn->(@args);
    }
    else {
        Carp::croak("Don't know type '$what'");
    }
}

sub with_dispatch(@tf) {
    return sub {
        my $it = List::MoreUtils::natatime 2, @tf;
        my ($type,$f);
        while ( ($type, $f) = $it->() ) {
            if ( Sq::Type::t_valid($type, \@_) ) {
                return $f->(@_);
            }
        }
        local $Carp::CarpLevel += 1;
        Carp::croak sprintf("No dispatch for: %s", Sq::Dump::dumps(\@_));
    };
}

sub type_cond(@tf) {
    return sub($any) {
        my $it = List::MoreUtils::natatime 2, @tf;
        my ($type,$f);
        while ( ($type, $f) = $it->() ) {
            if ( Sq::Type::t_valid($type, $any) ) {
                return $f->($any);
            }
        }
        local $Carp::CarpLevel += 1;
        Carp::croak sprintf("No dispatch for: %s", Sq::Dump::dumps($any));
    };
}

# creates functions with multi-dispatch based on input type
sub multi($name, @tf) {
    my $full = caller . '::' . $name;
    Sq::Reflection::set_func($full, with_dispatch(@tf));
    return;
}

sub array(@array) { bless(\@array, 'Array') }
sub hash (%hash)  { bless(\%hash,  'Hash')  }

# returns a function that generates a hash from just the values. See: t/00-core.t
sub record(@fields) {
    return sub(@args) {
        my $hash = bless({}, 'Hash');
        for (my $idx=0; $idx < @args; $idx++) {
            $hash->{$fields[$idx]} = $args[$idx];
        }
        return $hash;
    }
}

sub fn($name,$sub) {
    my $full = caller . '::' . $name;
    Sq::Reflection::set_func($full,$sub);
}

1;
