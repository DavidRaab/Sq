package Sq;
use 5.036;
our $VERSION = '0.006';
use Scalar::Util ();
use Sub::Exporter -setup => {
    exports => [
        qw(sq call key assign),
        qw(is_num is_str),
        qw(id fst snd),
        Some => sub { \&Option::Some            },
        None => sub { \&Option::None            },
        Ok   => sub { \&Result::Ok              },
        Err  => sub { \&Result::Err             },
        lazy => sub { \&Sq::Control::Lazy::lazy },
    ],
    groups => {
        default => [qw(id fst snd key assign is_str is_num Some None sq Ok Err call lazy)],
    },
};

# Load lazy keyword
use Sq::Control::Lazy;

# Load Basic Data Types
use Sq::Core::Option;
use Sq::Core::Result;

# Load Collections Modules
use Sq::Collections::Hash;
use Sq::Collections::Array;
use Sq::Collections::Queue;
use Sq::Collections::List;
use Sq::Collections::Seq;
use Sq::Collections::Heap;

# Load Dumping
use Sq::Dump;

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
sub call($method, @args) {
    return sub($obj) { $obj->$method(@args) };
}

# allows writing a code block to create a value
sub assign :prototype(&) {
    return $_[0]->();
}

sub is_str :prototype($) {
    return ref $_[0] eq '' ? 1 : 0;
}

sub is_num :prototype($) {
    return Scalar::Util::looks_like_number($_[0]);
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
        for my $key ( keys %$any ) {
            sq($any->{$key});
        }
    }
    elsif ( $type eq 'Array' ) {
        for my $x ( @$any ) {
            sq($x);
        }
    }
    elsif ( $type eq 'Option' ) {
        sq($any->[0]) if @$any;
    }
    else {
        # Do nothing for unknown type
    }
    return $any;
}

# Access to Sq::Io
sub io($class) { return 'Sq::Io' }

1;
