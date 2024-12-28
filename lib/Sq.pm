package Sq;
use 5.036;
our $VERSION = '0.007';
use Carp ();
use Scalar::Util ();
my $export_funcs;
sub import {
    my ( $own, @requested ) = @_;
    my ( $pkg ) = caller;
    no strict 'refs'; ## no critic
    state @funcs = (
        qw(sq call key assign seq),
        qw(is_num is_str is_array is_hash is_seq is_opt is_result is_ref),
        qw(id fst snd),
        qw(by_num by_str by_stri),
    );

    # Otherwise just requested
    if ( @requested > 0 ) {
        # Build cache for better checking - but only once and only when needed
        if ( !defined $export_funcs ) {
            $export_funcs = { map { $_ => 1 } @funcs };
        }
        for my $request ( @requested ) {
            Carp::croak "Export Func '$request' does not exists"
                if !exists $export_funcs->{$request};
            *{"$pkg\::$request"} = \&$request;
        }
    }
    # Export ALL
    else {
        for my $func ( @funcs ) {
            *{"${pkg}::$func"} = \&$func;
        }
    }

    # TODO: Not always export
    *{"$pkg\::Some"}  = \&Option::Some;
    *{"$pkg\::None"}  = \&Option::None;
    *{"$pkg\::Ok"}    = \&Result::Ok;
    *{"$pkg\::Err"}   = \&Result::Err;
    *{"$pkg\::lazy"}  = \&Sq::Core::Lazy::lazy;
    *{"$pkg\::equal"} = \&Sq::Equality::equal;
    *{"$pkg\::dump"}  = \&Sq::Dump::dump;
    *{"$pkg\::dumpw"} = \&Sq::Dump::dumpw;
}

# Load Reflection
use Sq::Reflection;

# Load Basic Data Types
use Sq::Core::Lazy;
use Sq::Core::Option;
use Sq::Core::Result;

# Load Collections Modules
use Sq::Collections::Array;
use Sq::Collections::Hash;
use Sq::Collections::Seq;
use Sq::Collections::Queue;
use Sq::Collections::List;
use Sq::Collections::Heap;

# Load other basic functionality
use Sq::Dump;
use Sq::Equality;

# IO
use Sq::Io;

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

sub is_num :prototype($) {
    return Scalar::Util::looks_like_number($_[0]);
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

sub is_seq :prototype($) {
    return ref $_[0] eq 'Seq' ? 1 : 0;
}

sub is_opt :prototype($) {
    return ref $_[0] eq 'Option' ? 1 : 0;
}

sub is_result :prototype($) {
    return ref $_[0] eq 'Result' ? 1 : 0;
}

sub is_ref :prototype($$) {
    return ref $_[1] eq $_[0] ? 1 : 0;
}

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
    state $fn = sub($x,$y) { fc $x cmp $y };
    return $fn;
}

# recursively traverse a data-structure and add Array/Hash blessings
sub sq($any) {
    my $type = ref $any;

    # Add Array/Hash blessing to current ref
    CORE::bless($any, 'Array') if $type eq 'ARRAY';
    CORE::bless($any, 'Hash')  if $type eq 'HASH';

    $type = ref $any;
    # recursively go through each data-structure
    if ( $type eq 'Hash' ) {
        for ( keys %$any ) {
            sq($any->{$_});
        }
    }
    elsif ( $type eq 'Array' ) {
        for my $x ( @$any ) { sq($x) }
    }
    elsif ( $type eq 'Option' ) {
        for my $x ( @$any ) { sq($x) }
    }
    elsif ( $type eq 'Result' ) {
        sq($any->[1]);
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
        return sub {
            return undef if $abort;
            my $v = $data[$idx++];
            return $v if defined $v;
            $abort = 1;
            return undef;
        }
    }, 'Seq');
}

# Access to Sq::Io
sub io($class) { return 'Sq::Io' }

1;
