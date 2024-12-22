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
or representing **Ok/Err** values.

It is planned to implement **Discriminated Unions**.

Instead of classes, typing is done with an Structural Typing approach. It is
available under `Sq::Type` but not fully documented yet. This can be used as
an argument validator or even as a testing tool.

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
* [Sq::Core::Result](lib/Sq/Core/Result.pod) (Partially implemented)
* [Sq::Collections::Seq](lib/Sq/Collections/Seq.pod)
* [Sq::Collections::Hash](lib/Sq/Collections/Hash.pod)
* [Sq::Collections::Array](lib/Sq/Collections/Array.pod)
* [Sq::Collections::Queue](lib/Sq/Collections/Queue.pm)
* [Sq::Collections::List](lib/Sq/Collections/List.pm)
* [Sq::Collections::Heap](lib/Sq/Collections/Heap.pod)
* [Sq::Type](lib/Sq/Manual/Type/00-Intro.pod)
* [Sq::Parser](lib/Sq/Manual/Parser/00-intro.pod)
* [Sq::Signature](lib/Sq/Manual/Type/00-Intro.pod)
* [Sq::Dump](lib/Sq/Dump.pm) (used for `->dump` and `->dumpw` methods on types)

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
use Sq;

# Fibonacci Generator
my $fib =
    Seq->concat(
        Seq->new(1,1),
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
        Seq->new(qw/clubs spades hearts diamond/),
        Seq->new(qw/7 8 9 10 J Q K A/)
    );

use Path::Tiny qw(path);
# get the maximum id from test-files so far
my $maximum_id =
    Seq
    ->new(    path('t')->children )
    ->map(    sub($x) { $x->basename })
    ->choose( sub($x) { $x =~ m/\A(\d+) .* \.t\z/xms ? $1 : undef })
    ->max->or(0); # or 0 if the sequence is empty
```

# Parser

Here is an example of the Parser to parse a number with suffix.

```perl
use Sq;
use Sq::Parser;

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
the opposite. It allows creating Parser with regexes in mind and for good
performance you should try to cramp as much as possible into Perl's regeyes. So
here is the above parser re-written using Perl Regexes.

```perl
use Sq;
use Sq::Parser;

my $num = assign {
    my $to_num = sub($num,$suffix) {
        return $num                      if fc $suffix eq fc 'b';
        return $num * 1024               if fc $suffix eq fc 'kb';
        return $num * 1024 * 1024        if fc $suffix eq fc 'mb';
        return $num * 1024 * 1024 * 1024 if fc $suffix eq fc 'gb';
    };

    p_many(
        p_matchf(qr/\s* ,? \s* (\d+) \s* (b|kb|mb|gb)/xi, $to_num),
    );
};

is(p_run($num, "1  b, 1kb"),         Some([1, 1024]), '1 b & 1kb');
is(p_run($num, "1 kb, 1gb"), Some([1024,1073741824]), '1 kb & 1gb');
is(p_run($num, "1 Mb"),              Some([1048576]), '1 mb');
is(p_run($num, "1 gb"),           Some([1073741824]), '1 gb');
```

# Data over Classes

```perl
use Sq;

my $album = sq {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => [
        {title => "Wanna Be Startin’ Somethin", duration => 363},
        {title => "Baby Be Mine",               duration => 260},
        {title => "The Girl Is Mine",           duration => 242},
        {title => "Thriller",                   duration => 357},
        {title => "Beat It",                    duration => 258},
        {title => "Billie Jean",                duration => 294},
        {title => "Human Nature",               duration => 246},
        {title => "P.Y.T.",                     duration => 239},
        {title => "The Lady in My Life",        duration => 300},
    ],
};

my $length = $album->length;           # 3 - hash has 3 keys
my $tracks = $album->{tracks}->length; # 9 - nine tracks

# 2559 - shortest version
my $album_runtime = $album->get('tracks')->map(call 'sum_by', key 'duration')->or(0);

# 2559 - expanded the "call" function
my $album_runtime = $album->get('tracks')->map(sub ($tracks) {
    $tracks->sum_by(key 'duration');
})->or(0);

# 2559 - expanded the "key" function
my $album_runtime = $album->get('tracks')->map(sub ($tracks) {
    $tracks->sum_by(sub($hash) {
        $hash->{duration}
    });
})->or(0);

# 2559 - Pure Perl version
my $album_runtime = assign {
    my $sum    = 0;
    my $tracks = $album->{tracks};
    if ( defined $tracks ) {
        for my $track ( @$tracks ) {
            $sum += $track->{duration};
        }
    }
    return $sum;
};
```

# Typing

```perl
use Sq;
use Sq::Type;

# Describes an address
my $address = t_hash(t_keys(
    street => t_str,
    city   => t_str,
    state  => t_str,
    zip    => t_match(qr/\A\d+\z/),
));

# A user containing an address
my $user  = t_hash(t_keys(
    id      => t_str,
    first   => t_str,
    last    => t_str,
    address => $address,
));

my $user1 = {
    id      => 1,
    first   => "David",
    last    => "Raab",
    address => {
        street => 'Wonder Street',
        city   => 'Wonder City',
        state  => 'Wonder State',
        zip    => '12345',
    },
};

my $user2 = {
    id      => 1,
    frist   => "David",   # Typo
    last    => "Raab",
    address => {
        street => 'Wonder Street',
        city   => 'Wonder City',
        state  => 'Wonder State',
        zip    => '12345',
    },
};

# Tests
is(t_run($user, $user1), Ok(1),                                '$user1 is a user');
is(t_run($user, $user2), Err("first does not exists on hash"), '$user2 has a typo');

# describes an album
my $is_album = assign {
    # checks for format and if min:seconds are not >= 60
    my $duration = t_matchf(qr/\A(\d\d):(\d\d)\z/, sub($min,$sec) {
        return if $min >= 60;
        return if $sec >= 60;
        return 1;
    });

    return
        t_hash(
            t_with_keys(qw/artist title tracks/),
            t_keys(
                artist => t_str(t_min 1),   # string must have at least 1 char
                title  => t_str(t_min 1),
                tracks => t_array(
                    t_min(1),              # Array must have at least 1 entry
                    t_of(t_hash(           # All entries must be hashes
                        t_with_keys(qw/name duration/),
                        t_keys(
                            name     => t_str,
                            duration => $duration))))));
};

my $result = t_run  ($is_album, $album); # Returns Result
my $bool   = t_valid($is_album, $album); # Returns boolean
t_assert($is_album, $album);             # Throws exception when not valid
```

# Signatures

The Type system can be used to add type-checking to any function. But the
idea is that this kind of type-checking is only added in developing / testing
and for code running in production the type-check is removed. It works like
the **Memoize** module by replacing a function with type-checking.

So in production you don't pay the price of type-checking in every function.
You just enable it when you need to find errors/bugs.

```perl
use Sq;
use Sq::Sig; # this adds type-checking to all kind of functions in Sq.

# throws an exception when Sq::Sig is loaded complaining that the array is not
# even-sized. Otherwise without Sq::Sig it gives some warnings but continues.
my $hash = sq([1,2,3])->as_hash;
```

You can add type-checking to any function.

```perl
use Sq;
use Sq::Type;
use Sq::Signature;

sub whatever($int, $str, $array_of_nums) {
    # ...
    return $hash;
}

# this adds type-checking to the function. Usually you put those signatures
# in its own file that can be loaded at will. This also correctly checks
# the return value of a function. So when you refactor/change code you get
# errors when you return the wrong things.
sig('main::whatever', t_int, t_str, t_array(t_of t_num), t_hash);

whatever("foo", "foo", [1,2,3]); # fails
whatever(  123, "foo", ["foo"]); # fails
whatever(  123,    [], [1,2,3]); # fails
whatever(123.3,   123,      []); # fails
whatever(  123,   123,      []); # ok - because "123" is also a valid string
whatever(  123, "foo",      []); # ok
whatever(  123, "foo", [1,2,3]); # ok
```

# EXPORT

It exports the following functions by default: sq, call, key, id, fst, snd, assign, is_str, is_num, Some, None, Ok, Err.

# SUPPORT

Development project is on Github [Perl-Sq](https://github.com/DavidRaab/Sq)

You can find documentation for this module with the perldoc command.

    perldoc Sq

You can also look for information at [my Blog on Perl Sq/Seq](https://davidraab.github.io/tags/perl-sq/)

# AUTHOR

David Raab, **davidraab83 at gmail.com**

# LICENSE AND COPYRIGHT

This software is Copyright (c) by David Raab.

This is free software, licensed under:

  The MIT (X11) License
