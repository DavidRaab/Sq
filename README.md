# NAME

Sq - A Language hosted in Perl

# SYNOPSIS

What is a programming language? The foundation of every programming language
are the data-structures the language provides you by default. The default
data-structures and their possibilites shape how you will build a solution.

Sq is a module that provides certain data-structures. Those data-structures
are meant as a replacement for the built-in Perl data-structures. But replacing
those data-structures will change the way how you code.

Sq currently provides a lazy sequence `Seq`, extension for `Array`, `Hash`,
a `Queue`, `List` and a `Heap` data-structure.

It uses an `Option` and `Result` type for representing the absence of values
or representing B<Ok/Err> values.

It is planned to implement B<Discriminated Unions>.

Instead of classes, typing is done with an Structural Typing approach. It is
available under `Sq::Type` but not completed and documented yet.
This can be used as an argument validator or even as a testing tool.

Under `Sq::Parser` there is a Combinator based approach to parsing. It
is already usuable and can be used for certain things but sill lacks some
features like useful error-messages.

`Sq` don't invent new syntax, it just uses Perl as much as possible. It
is also implemented in pure Perl so far.

The idea of `Sq` is to combine procedural and functional programming and
stick to a design that splits Data from Code. Because it leads to better
software, is easier to develop and has more reusable code.

The whole point is that it offers all basic operations you usually do in Perl
like reading files, directories, parsing in general, parsing arguments, testing
and a lot of other stuff in it's own System that uses the provided data-structures
like `Seq`, `Array`, `Option` and `Result` so you can use it as a foundation
to develop more abstract things without re-implementing the basics again and again.

# HISTORY

I started `Sq` first by just being a lazy Sequence and named it `Seq`.
But the `Seq` namespace in Perl was already taken, deleted, and the old
maintainer doesn't react to eMails anymore.

So I decided to just name it `Sq` instead. At the same time I already had
the idea to bring more stuff to Perl, like Records, Pattern Matching
and Discriminated Unions, also some other approach to type-checking.

So instead of releasing a dozens of seperate modules I thought about
making one module that just combines all this ideas together that also can
depend on each other. I wanted a short name, so i just removed the `e`
from `Seq` and just named it `Sq`. You still can pronounce it `Seq`.

There is no meaning/abreviation behind `Sq`. But when you can think of one
that makes sense or you like then feel free to contribute.

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
* [Sq::Collections::List](lib/Sq/Collections/List.pm)
* [Sq::Collections::Heap](lib/Sq/Collections/Heap.pod)
* [Sq::Type](lib/Sq/Type.pm)
* [Sq::Parser](lib/Sq/Manual/Parser/00-intro.pod)

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

# Parser

Here is an example of the Parser to parse a number with suffix.

```perl
my $num = assign {
    my $to_num = sub($num,$suffix) {
        return $num                      if $suffix eq 'b';
        return $num * 1024               if $suffix eq 'kb';
        return $num * 1024 * 1024        if $suffix eq 'mb';
        return $num * 1024 * 1024 * 1024 if $suffix eq 'gb';
    };

    p_many(
        p_maybe(p_match(qr/\s* , \s*/x)), # optional ,
        p_map(
            $to_num,
            p_many (p_strc(0 .. 9)), # digits
            p_match(qr/\s*/),        # whitespace
            p_strc (qw/b kb mb gb/), # suffix
        )
    );
};

# Tests
is(p_run($num, "1  b, 1kb"),         Some([1, 1024]), '1 b & 1kb');
is(p_run($num, "1 kb, 1gb"), Some([1024,1073741824]), '1 kb & 1gb');
is(p_run($num, "1 mb"),              Some([1048576]), '1 mb');
is(p_run($num, "1 gb"),           Some([1073741824]), '1 gb');
```

this is an exhausted example. `Sq::Parser` does not try to replace Regexes. Quite
the opposite. It allows creating Parser with regexes in mind. So here is the above
parser re-written using Perl Regexes.

```perl
my $num = assign {
    my $to_num = sub($num,$suffix) {
        return $num                      if $suffix eq 'b';
        return $num * 1024               if $suffix eq 'kb';
        return $num * 1024 * 1024        if $suffix eq 'mb';
        return $num * 1024 * 1024 * 1024 if $suffix eq 'gb';
    };

    p_many(
        p_matchf(qr/\s* ,? \s* (\d+) \s* (b|kb|mb|gb)/xi, $to_num),
    );
};

# Tests
is(p_run($num, "1  b, 1kb"),         Some([1, 1024]), '1 b & 1kb');
is(p_run($num, "1 kb, 1gb"), Some([1024,1073741824]), '1 kb & 1gb');
is(p_run($num, "1 mb"),              Some([1048576]), '1 mb');
is(p_run($num, "1 gb"),           Some([1073741824]), '1 gb');
```

# EXPORT

It exports the following functions by default: id, fst, snd, key, assign, is_str, is_num, Some, None.

# SUPPORT

Development project is on Github [Perl-Sq](https://github.com/DavidRaab/Sq)

You can find documentation for this module with the perldoc command.

    perldoc Sq

You can also look for information at [my Blog on Perl Seq](https://davidraab.github.io/tags/perl-seq/)

# AUTHOR

David Raab, **davidraab83 at gmail.com**

# LICENSE AND COPYRIGHT

This software is Copyright (c) by David Raab.

This is free software, licensed under:

  The MIT (X11) License
