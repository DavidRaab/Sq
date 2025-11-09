package Sq;
use 5.040;
our $VERSION = '0.007';
use Carp ();
# TODO:
#   Scalar::Util also loads List::Util. So theoretically List::Util
#   functions can be used everywhere. This is somewhat annoying
#   because i want to reduce loading time. And List::Util takes around
#   4ms to load. The only function i need from Scalar::Util is
#   looks_like_number(). When i find an alternative for this, i
#   could remove Scalar::Util and this way also List::Util loading.
use Scalar::Util ();
# This variable is by default 0 and will be set to 1 when user does
#
#     use Sq sig => 1
#
# Then all other modules that use Sq::Exporter will automatically load it's
# defined signature file (when some is defined).
our $LOAD_SIGNATURE = 0;
# All functions that are Exported
our @EXPORT = (
    qw(sq call key idx key_equal assign seq new),
    qw(is_num is_str is_array is_hash is_seq is_opt is_result is_sub is_regex is_ref get_type),
    qw(fn match multi dispatch with_dispatch type_cond),
    qw(id fst snd),
    qw(by_num by_str by_stri),
    qw(array hash record),
    qw(Str),
    Some    => sub { \&Option::Some           },
    None    => sub { \&Option::None           },
    Ok      => sub { \&Result::Ok             },
    Err     => sub { \&Result::Err            },
    lazy    => sub { \&Sq::Lazy::lazy         },
    equal   => sub { \&Sq::Equality::equal    },
    dump    => sub { \&Sq::Dump::dump         },
    dumps   => sub { \&Sq::Dump::dumps        },
    type    => sub { \&Sq::Type::type         },
    is_type => sub { \&Sq::Type::t_valid      },
    static  => sub { \&Sq::Reflection::static },
    union   => sub { \&Sq::Core::DU::union    },
    copy    => sub { \&Sq::Copy::copy         },
);

# This is a hash that is build only on the first ->import call. It builds a
# uniform hash with the FUNCNAME => SUBREF mapping so exporting code becomes
# easier to handle.
my $export_funcs;
sub import {
    my ( $own, @requested ) = @_;
    my ( $pkg ) = caller;

    no strict 'refs'; ## no critic

    # Build hash/cache
    if ( !defined $export_funcs ) {
        my $idx = 0;
        while ( $idx < @EXPORT ) {
            my $func = $EXPORT[$idx];
            my $next = $EXPORT[$idx+1];

            if ( ref $next eq 'CODE' ) {
                $export_funcs->{$func} = $next;
                $idx += 2;
            }
            else {
                # This must be a sub-ref and therefore lazy executed, because
                # maybe the signature is loaded after this code. When this is
                # not lazy. No function with type-checking will be exported.
                $export_funcs->{$func} = sub { *{$func}{CODE} };
                $idx += 1;
            }
        }
    }

    # Build new @req with options removed
    # @req contains the functions to be exported
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
        require Sq::Sig::Core;
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

# Load Core functionality
use Sq::Reflection;
use Sq::Core;        # equal(), copy(), lazy {}, Option, Result
use Sq::Core::DU;    # Discriminated Unions
use Sq::Dump;        # dump(), dumps()
use Sq::Type;        # Type System

# Load Collections
use Sq::Array;
use Sq::Hash;
use Sq::Seq;
use Sq::Queue;
use Sq::List;
use Sq::Heap;

# Access to submodules
sub io($) {
    if ( !exists $INC{'Sq/Io.pm'} ) {
        require Sq::Io;
        Sq::Io->load_signature();
    }
    return 'Sq::Io';
}
sub fs($) {
    if ( !exists $INC{'Sq/Fs.pm'} ) {
        require Sq::Fs;
        Sq::Fs->load_signature();
    }
    return 'Sq::Fs';
}
sub math($) {
    if ( !exists $INC{'Sq/Math.pm'} ) {
        require Sq::Math;
        Sq::Math->load_signature();
    }
    return 'Sq::Math';
}
sub fmt($) {
    if ( !exists $INC{'Sq/Fmt.pm'} ) {
        require Sq::Fmt;
        Sq::Fmt->load_signature();
    }
    return 'Sq::Fmt';
}
sub bench($) {
    if ( !exists $INC{'Sq/Bench.pm'} ) {
        require Sq::Bench;
        Sq::Bench->load_signature();
    }
    return 'Sq::Bench';
}
sub rand($) {
    if ( !exists $INC{'Sq/Rand.pm'} ) {
        require Sq::Rand;
        Sq::Rand->load_signature();
    }
    return 'Sq::Rand';
}
sub p($) {
    if ( !exists $INC{'Sq/P.pm'} ) {
        require Sq::P;
        Sq::P->load_signature();
    }
    return 'Sq::P';
}

# Str Module
sub Str :prototype() {
    if ( !exists $INC{'Sq/Core/Str.pm'} ) {
        require Sq::Core::Str;
        Sq::Core::Str->load_signature();
    }
    return 'Sq::Core::Str';
}

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

sub key_equal($key, $value) {
    return sub($hash) { Sq::Equality::equal($hash->{$key}, $value) };
}

# creates a function that selects a specific index of an array
sub idx :prototype($) {
    my ($index) = @_;
    return sub($array) { $array->[$index] };
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

sub get_type($any) {
    my $ref = ref $any;
    if ( $ref eq '' ) {
        return 'Num' if is_num($any);
        return 'Str';
    }
    return 'Array' if $ref eq 'Array' || $ref eq 'ARRAY';
    return 'Hash'  if $ref eq 'Hash'  || $ref eq 'HASH';
    return 'Sub'   if $ref eq 'CODE';
    return 'Regex' if $ref eq 'Regexp';
    return $ref;
}

### Comparision Functions

sub by_num :prototype() {
    state $fn = sub { $_[0] <=> $_[1] };
    return $fn;
}

sub by_str :prototype() {
    state $fn = sub { $_[0] cmp $_[1] };
    return $fn;
}

sub by_stri :prototype() {
    state $fn = sub { fc($_[0]) cmp fc($_[1]) };
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
    # TODO: I also could check for Seq and return a new Seq that adds the
    #       blessings to it's inner values. But at the moment i never came
    #       across that (problem).
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
        Array => \&array,
        Hash  => \&hash,
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

# TYPE -> Function
# Returns a function that expects multiple arguments and passes all arguments
# to the function an an array-ref
sub with_dispatch(@tf) {
    return sub {
        for my ($type,$f) ( @tf ) {
            if ( Sq::Type::t_valid($type, \@_) ) {
                return $f->(@_);
            }
        }
        local $Carp::CarpLevel += 1;
        Carp::croak sprintf("No dispatch for: %s", Sq::Dump::dumps(\@_));
    };
}

# TYPE -> Function
# Similar to with_dispatch() but returns a function that expects only a single
# argument. Thus it only passes one argument to the function instead of an
# array-ref. This changes what you provide as TYPE. When you use with_dispatch()
# you usually start with "tuple, tuplev, array". with type_cond() you directly
# pass the TYPE of the first argument.
sub type_cond(@tf) {
    return sub($any) {
        for my ($type,$f) ( @tf ) {
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

# Helper for string dipatch table. It just dispatches a string on a hash and
# calls the apropiate function. It throws an exception when the hash has no
# dispatch defined. That's usually what you want when you care for correct code,
# and i don't have the patience to always do the if checking and error-throwing
# myself.
sub dispatch {
    if ( @_ == 0 ) {
        Carp::croak "dispatch: No arguments.\n";
    }
    elsif ( @_ == 2 ) {
        my ($f_key, $case_sub) = @_;
        Carp::croak "dispatch: First argument must be sub in two-argument call" if !is_sub($f_key);
        Carp::croak "dispatch: Must be hash in two-argument call"               if !is_hash($case_sub);
        return sub($x) {
            my $key  = $f_key->($x);
            my $func = $case_sub->{$key};
            if ( defined $func ) {
                return $func->($x);
            }
            else {
                Carp::croak "dispatch: '$key' not provided as a case.\n";
            }
        }
    }
    elsif ( @_ < 5 ) {
        Carp::croak "dispatch: Expects two or at least five arguments!\n";
    }
    else {
        my ($key, %case_sub) = @_;
        Carp::croak "dispatch: Expects a Str as first argument" if !is_str($key);
        my $func = $case_sub{$key};
        if ( defined $func ) {
            return $func->();
        }
        else {
            Carp::croak "dispatch: '$key' not provided as a case.\n";
        }
    }
}

# Reserved:
#
# i first wanted to implemented a fraction of Pattern Matching. But decided to
# change the name to dispatch() as that it what it does at the moment. It
# just does a dispatch on a dispatch-table. But by naming it dispatch() it can
# be a stable function. Otherwise i already can do everything what i expact
# todo with match(). I can do it with type_cond() or with_dispatch() it expects
# a TYPE, and the TYPE system i have built is complete enough todo any kind of
# TYPE checking. But it isn't so "short". Maybe i implement a function that can
# work with common type-definitions that are passed as a string. Those are not
# so complete as what you can do with with_dispatch() or type_cond() but
# contains 90% of what you usually do in a pattern-match. Then i name this
# whole combination match(). But this is still in draft. Still i want to reserve
# match() as a keyword. Maybe i also can do a method-redirect. For example when
# a Discriminated Union is passed it just does a method-dispatch and so on.
no warnings 'once';
sub match($any, @case_sub) { ... }

1;
