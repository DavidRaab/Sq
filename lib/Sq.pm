package Sq;
use 5.036;
our $VERSION = '0.006';
use Scalar::Util ();
use Sub::Exporter -setup => {
    exports => [
        qw(id fst snd key assign is_str is_num),
        Some => sub { \&Option::Some },
        None => sub { \&Option::None },
    ],
    groups => {
        default => [qw(id fst snd key assign is_str is_num Some None)],
    },
};

# Load Basic Data Types
use Sq::Core::Option;

# Load Collections Modules
use Sq::Collections::Hash;
use Sq::Collections::Array;
use Sq::Collections::Queue;
use Sq::Collections::List;
use Sq::Collections::Seq;
use Sq::Collections::Heap;
# provides to_* from_* functions for different packages
use Sq::Collections::Glue;
use Sq::Io;

# Important functions used in FP code. So adding them.
sub id  :prototype($) { return $_[0]    }
sub fst :prototype($) { return $_[0][0] }
sub snd :prototype($) { return $_[0][1] }

# a helper to create a function for selecting a hash-key
sub key :prototype($) {
    my $name = $_[0];
    return sub($hash) { return $hash->{$name} };
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

# Access to Sq::Io
sub io($class) { return 'Sq::Io' }

1;

=head1 NAME

Sq - The Sq language

=head1 SYNOPSIS

What is a programming language? The foundation of every programming language
are the data-structures the language provides you by default. The default
data-structures and their possibilites shape how you will build a solution.

Sq is a module that provides certain data-structures. Those data-structures
are meant as a replacement for the built-in Perl data-structures. But replacing
those data-structures will change the way how you code.

Sq provides an immutable lazy sequence as its core data-structure (Seq),
an immutable list (List), mutable Array (Array) and a mutable Queue (Queue).

Those data-structures will share the same API as much as possible.

Besides the above it will also provide a (Record) as an immutable Hash and
Discriminated Unions.

Instead of classes, typing is done with an Structural Typing approach. This
can be used as an argument validator or even as a testing tool.

Sq don't invent new syntax, it just uses Perl as much as possible. It
is also implemented in pure Perl so far.

Besides just data-structures the idea of Sq is to have a certain high-level
API for basic programming tasks. An easier API for doing all kinds of
File System operations or reading and writing from files like CSV or JSON that
uses the data-structures of this module.

=head1 IMPORTED FUNCTIONS

is_str, is_num, Some, None

=head2 id

return its input as-is

    sub id($x) { return $x }

=head2 fst

return the first element of an array

    sub fst($array) { return $array->[0] }

=head2 snd

return the second element of an array

    sub snd($array) { return $array->[1] }

=head2 key

generates a function that picks a value from a hash.

    sub key($name) { sub($hash) { return $hash->{$name} } }

=head2 assign

allows you to assign a value, but also do a computation.

    my $value = assign {
        my $x = ...  # code to compute $x
        my $y = ...  # code to compute $y
        $x + $y;
    };

Same as

    my $value;
    {
        my $x = ...  # code to compute $x
        my $y = ...  # code to compute $y
        $value = $x + $y;
    }

=head1 AUTOMATICALLY LOADED MODULES

=over 4

=item L<Sq::Core::Option>

=item L<Sq::Io>

=item L<Sq::Collections::Hash>

=item L<Sq::Collections::Array>

=item L<Sq::Collections::Queue>

=item L<Sq::Collections::List>

=item L<Sq::Collections::Seq>

=item L<Sq::Collections::Heap>

=back

