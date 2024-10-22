# NAME

Sq - A Language hosted in Perl

# SYNOPSIS

What is a programming language anyway? Besides its syntax I think the default
data-structures a programming language ships with has maybe the greatest
impact on how someone programs.

Lisp is a language that is basically built around the idea that everything is
just a List. Haskell took the idea that this List must be lazy evaluated.
F# ships by default with an Immutable List, immutable Record and so on,
so you also use them. C basically has no data-structure at all, just pointers
to memory, so you basically just use pointers to memory and use them
as arrays.

Perl ships with Array and Hash by default, and not surprisngly they are
used everywhere to built stuff on top of it.

`Sq` in that regards try to enhance the default `Array` and `Hash`
implementation by giving them just more functions to work with, but it doesn't
try to replace them.

After getting used working in F# it actually becomes annoying to work in other
languages that don't offer 100+ functions to just manipulate Lists. After
working in Perl for 15+ years i know a lot how to implement a lot of common
tasks efficently and with less code, and sometimes I am also annoyed that
I have to implement those *patterns* again and again instead of giving
them a name.

Then there are modules like List::Util that offers more functions, and somehow
I was annoyed by the order you have to write them, how some functions are
named, or that they are still some functions missing.

But the greatest problem was that there is basically no lazy Sequence
implementation at all. And nearly zero immutable data-structures at all.

`Sq` currently ships with Seq, Array, Hash, Heap and List.

At the moment it is just a hobby project on my own that I work on occasionally.

Still everything is intended to be usuable with good performance. I don't
try to enforce for example an *immutable all the way down* on top of Perl. I
am also interested that it works seaminglessly with whatever else you use.

For example you see this design in the Array module. You can write.

    my $nums = Array->init(10, sub($idx) { $idx });

and it creates an `Array` with 10 items that just contains its indexes as
values. But `$nums` here is just a basic Perl Array, I am not trying to
re-implement an Array. So you can use `$nums` like any array-reference
you are used in Perl.

    for my $x ( @$nums ) {
        say $x;
    }

Sure, some other data-structures like `Seq` have to be their own
implementation as their are no Perl implementations that provide the same
functionality.

Besides data-structures what makes a language unique is how you check for
types, for example static and dynamic typed. Other *frameworks* like Moose for
example try to give you more a *static-typing* approach with its classes and
type-check against specific concrete classes or roles, here I will try a
different approach build around the concept of dynamic-typing and having
data, but this is still in work.

# HISTORY

I started `Sq` first by just being a lazy Sequence and named it `Seq`.
But the `Seq` namespace in Perl was already taken, deleted, and the old
maintainer doesn't react to eMails anymore.

So I decided to just name it `Sq` instead. At the same time I already had
the idea to bring more stuff to Perl, like Records, Pattern Matching
and Discriminated Unions, also some other approach to type-checking.

So instead of realasing a dozens of seperate modules I thought about
making one module that just combines all this ideas together. So `Sq` was
born.

# Implemented so Far

Most stuff at the moment is just a place-holder, maybe some will never be
implemented, but some stuff is already usable and tested. So if you really
want to look around of what is usable you should look at the tests at the
moment. I anyway think that code is the best way to see and understand code.

But the API itself is not fixed, means some stuff is very likely to change.

I wouldn't recommend this module at the moment to build something critical
unless you are fine that you maybe need sometimes small-fixes to make code
working again.

* [Sq::Core::Option](lib/Sq/Core/Option.pod)
* [Sq::Collections::Seq](lib/Sq/Collections/Seq.pod)
* [Sq::Collections::Hash](lib/Sq/Collections/Hash.pm)
* [Sq::Collections::Array](lib/Sq/Collections/Array.pod)
* [Sq::Collections::Queue](lib/Sq/Collections/Queue.pm)
* [Sq::Collections::List](lib/Sq/Collections/List.pod)
* [Sq::Collections::Heap](lib/Sq/Collections/Heap.pm)

# Seq Module

As I started everything with the `Seq` module, here are some example
how to use `Seq`. Keep in mind that `Seq` is a lazy data-structure, so nothing
is computed until you start *querying* for data. And only then only as much
is computed as needed.

But a sequence is not just an iterator. An iterator usually ends at some
point, then either a new iterator must be created or the iterator must be
resetted.

A `Seq` is more like an *immutable-iterator*. So it defines a computation that
you can execute and iterate as often as you wish. In some sense I think
that this design is more what someone expects using such a module.

```perl
use v5.36;
use Seq;

# Fibonacci Generator
my $fib =
    Seq->concat(
        Seq->wrap(1,1),
        Seq->unfold([1,1], sub($state) {
            my $next = $state->[0] + $state->[1];
            return $next, [$state->[1],$next];
        })
    );

# prints: 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765
$fib->take(20)->iter(sub($x) {
    say $x;
});

# you can use the same $fib again, now prints: 1 1 2 3 5
$fib->take(5)->iter(sub($x) {
    say $x;
});

# Represents all possible combinations
# [[clubs => 7], [clubs => 8], [clubs => 9], ...]
my $cards =
    Seq::cartesian(
        Seq->wrap(qw/clubs spades hearts diamond/),
        Seq->wrap(qw/7 8 9 10 B D K A/)
    );

use Path::Tiny qw(path);
# get the maximum id from test-files so far
my $maximum_id =
    Seq
    ->wrap(   path('t')->children )
    ->map(    sub($x) { $x->basename })
    ->choose( sub($x) { $x =~ m/\A(\d+) .* \.t\z/xms ? $1 : undef })
    ->max(0); # or 0 if the sequence is empty
```

# EXPORT

It exports the following functions by default: id, fst, snd, key, assign, is_str, is_num, Some, None.

# SUPPORT

Development project is on Github [Perl-Sq](https://github.com/DavidRaab/Sq)

You can find documentation for this module with the perldoc command.

    perldoc Sq

You can also look for information at [my Blog on Perl Seq](https://davidraab.github.io/tags/perl-seq/)

# AUTHOR

David Raab, C<< <davidraab83 at gmail.com> >>

# LICENSE AND COPYRIGHT

This software is Copyright (c) by David Raab.

This is free software, licensed under:

  The MIT (X11) License
