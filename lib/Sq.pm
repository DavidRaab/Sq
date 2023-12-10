package Sq;
use 5.036;
our $VERSION = '0.006';
use Sub::Exporter -setup => {
    exports => [
        qw(id fst snd key assign),
    ],
    groups => {
        default => [qw(id fst snd key assign)],
    },
};
use Sq::Collections::Seq;

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
