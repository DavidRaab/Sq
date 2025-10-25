# NAME

Sq - A Language hosted in Perl

Sq is a programing model that focus on procedural and functional programming
and combines the best of both. It provides an `Array` and `Hash` package by
default that extends Perl's built-in Arrays and Hashes for many functions so
you don't need to write them yourself.

`Seq` is a lazy sequence implementation that tries to be as compatible to `Array`
as much as possible. Just being lazy evaluated. Think of it as an F# Seq, C# Linq
or Java Streams implementation.

Error handling is done by an `Option` or `Result` data-type. Exceptions are
avoided as much as possible. Only with very very few exceptions.

Sq provides an `equal` function implementation that by default can compare
recursive data-types that can compare `Array`, `Hash`, `Seq`, `Option` and
`Result` by default, and some more. This function is also used by the internal
testing system `Sq::Test`.

`Sq::Test` itself is used to already test `Sq` itself. It's limited functionality
is a feature.

With `dump` you get a function that by default can dump data. Usually data
are dumped in a way that are human readable. Most of the time you can `dump`
data copy and paste it, and put the result into a test.

`Sq` doesn't try to eleminate dynamic-typing. Dynamic typing can have hughe
benefits and make code easy if used well. But sometimes some types are helpful.
With `Sq::Type` a function based type-system is implemented. Any function
that returns a boolean can be turned into a type-check. This way types and
restriction that aren't possible in a static typed language are possible.

But typing in a dynamic-typed language has some overhead, as it is code that
always must run on every invocation. With `Sq::Signature` a system is provided
to add type-checking to function when needed, and remove them when not needed.
So for example you can add type-checks in your test-suite and get better and
faster errors when something doesn't work as you expected. At normal runtime
you can remove the type-checks and your functions runs without any type-checks
at full speed.

`Sq` doesn't try to be low-level. It also provides common task. For example
calling `my $csv = Sq->io->csv_read("file.csv")` opens up a CSV file and returns you a `Seq` that you can use with all possible functions.

`Sq` provides a lazy loading mechanism of modules. For example at the current
moment calling `Sq->io->csv_read()` will load `Text::CSV`. When you never call
that function, `Text::CSV` is never loaded, this keeps the loading time of
`Sq` very fast.

Some more things are provided and will come, but this is just a short overview.

# Parser

Here is an example of the Parser to parse a number with suffix.

```perl
use Sq;
use Sq::Parser; # this imports all the "p_*" functions

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
performance you should try to cramp as much as possible into Perl's regexes. So
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
Maybe you will ask: What is the point of using Sq::Parser if most should
anyway be done in Regexes? Regexes can do a lot in Perl, you also can write
recursive regexes, extract data with it and run code at any certain point.
It's powerful but those extra features are hard to use. For all the extra
features you get a nearly not rememberable syntax anymore. Sq::Parser fixes
this.

For example everything in braces `()` is auto-extracted for you, you just
pass a function like in `p_matchf` and write the function of what should be
done. For example the Parser not only matches digits, it already transform
the input into bytes.

Now what i can do is for example save the above code, and just put it into
a function. I make it callable as


```perl
# TODO: think about name
my $num = $Sq->p->i_dont_know_name_yet();
```

I hope you see of what `Sq` will become. Next ideas are that i want to write
a Command CLI Argument. The idea is that you can easily use the Parser and the
type-system. And sure always provide the abstract things as part of the
base system.

Somehow Monolothics but, but just works better. YAGNI. When it is someday needed
it will be implemented.

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

# call($method, @args) -> sub($obj)
# call() creates a function that when passed an $obj it will call $obj->$method(@args)
# 2559 - call expanded
my $album_runtime = $album->get('tracks')->map(sub ($tracks) {
    $tracks->sum_by(key 'duration');
})->or(0);

# key($key) -> sub($hash)
# key() creates a function that when passed a $hash returns the field of it
# 2559 - expanded the "key" function
my $album_runtime = $album->get('tracks')->map(sub ($tracks) {
    $tracks->sum_by(sub($hash) {
        $hash->{duration}
    });
})->or(0);

# except assign {} it is pure-perl.
.
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

The shortest version of code is sometimes harder to understand, as it needs
more time to understand, but it also makes your thinking more abstract. The
shortest version for example is just "one-line". But just focus on reading
the words, not the extra symbols, then you read:

"tracks", "map", "sum_by", "key", "duration" "or" 0

This translates to:

On all "tracks", (map) change each item, create the sum by picking the
(duration) of each hash. (or) return 0 when tracks is empty

You must learn what the word "map" means, but more abstract concepts make
thinks easier to understand. Otherwise by just reading the words you maybe
can assume what the code does.


# Default Equality

Loading `Sq` automatically loads an `equal` function that can recursively check
a data-structure to be equal or not. By default it supports checking of `Array`,
`Hash`, `Seq`, `Option` and `Result` and sure also comparing numbers and strings.

By default this function is also installed as a method/function into the above
packages, so you also can call `equal` as a method on those types.

```perl
# Sq enhanced data-structure
my $album1 = sq {
    Artist => 'Queen',
    Title  => 'Greatest Hits',
    Tracks => Seq->new(
        { Title => 'We will Rock You'          },
        { Title => 'Radio Gaga'                },
        { Title => 'Who Wants To Life Forever' },
        { Title => "You Don't Fool Me"         },
    ),
    Tags => Some(qw/80/),
};

# pure perl data-structure
my $album2 = {
    Artist => 'Queen',
    Title  => 'Greatest Hits',
    Tracks => Seq->new(
        { Title => 'We will Rock You'          },
        { Title => 'Radio Gaga'                },
        { Title => 'Who Wants To Life Forever' },
        { Title => "You Don't Fool Me"         },
    ),
    Tags => Some(qw/80/),
};

my $bool = equal($album1, $album2); # 1
my $bool = $album1->equal($album2); # 1
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
is(t_run($address, $users[0]{address}), Ok(1),
    '$users[0] is addr');
is(t_run($user, $users[0]), Ok(1),
    '$users[0] is a user');
is(t_run($user, $users[1]), Err("hash: keys: 'first' not defined"),
    '$users[1] has a typo');

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
            # This check is not needed. t_keys also does that. But you could
            # have this line alone. Or just add additional fields that don't
            # need to be specified with a type. Also the type check
            # can be faster. All rules are executed one after another. So when
            # t_with_keys fails, everything fails. and further tests don't need
            # to be checked. t_keys must recurse into it's checks.
            t_with_keys(qw/artist title tracks/),
            t_keys(
                artist => t_str(t_min 1),  # string must have at least 1 char
                title  => t_str(t_min(1), t_max(255)),
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
idea is that this kind of type-checking is only added in developing / testing.
For code running in production the type-check is removed. It works like
the **Memoize** module by replacing a function with type-checking.

So in production you don't pay the price of type-checking in every function.
You just enable it when you need to find errors/bugs or during normal development
to find quickly type-errors.

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
whatever(  123, "123",      []); # ok - because "123" is also a valid string
whatever(  123, "foo",      []); # ok
whatever(  123, "foo", [1,2,3]); # ok
```

This is the signature of `Option::match`.

```perl
my $matches = t_hash(t_keys(
    Some => t_sub,
    None => t_sub,
));
sigt('Option::match', t_tuplev($opt, t_as_hash($matches)), $any);

# this is how a match call looks
my $result =
    $opt->match(
        Some => sub($x) { $x * $x },
        None => sub     { 0       },
    );

# this will throw an exception because "some/none" instead of "Some/None"
# was passed.
my $result =
    $opt->match(
        some => sub($x) { $x * $x },
        none => sub     { 0       },
    );
```

# Seq Module

`Seq` is a lazy data-structure that only starts computing things when you
ask it. It only computes as much things it needs. You can think
of them as *immutable-iterators*.

```perl
use Sq;

# Does nothing.
my $big = Seq->range(1, 1_000_000_000);

# Fibonacci Generator - also does no computation.
# It will generate fibonacci forever when this would be possible. It isn't
# because it works on 64-bit floats
my $fib =
    Seq->concat(
        seq { 1,1 },
        Seq->unfold([1,1], sub($state) {
            my $next = $state->[0] + $state->[1];
            return $next, [$state->[1],$next];
        })
    );

# Still does nothing. But $smaller will only contain the first 10_000 items
# when you ask it for data
my $smaller = $big->take(10_000);

# prints: 1 1 2 3 5 8 13 21 34 55 89 144 233 377 610 987 1597 2584 4181 6765
# never more than one number needs to be in memory.
$fib->take(20)->iter(sub($x) {
    say $x;
});

# you can use the same $fib again, now prints: 1 1 2 3 5
# this freshly recomputes the first 5 items.
$fib->take(5)->iter(sub($x) {
    say $x;
});

# Represents all possible combinations
# seq { [clubs => 7], [clubs => 8], [clubs => 9], ... }
my $cards =
    Seq::cartesian(
        seq { qw/clubs spades hearts diamond/ },
        seq { qw/7 8 9 10 J Q K A/            },
    );

use Path::Tiny qw(path);
# get the maximum id from test-files so far
my $maximum_id =
    Sq->fs
    ->children('t')              # a sequence of Path::Tiny objects
    ->map(call 'basename')       # calls ->basename method on objects
    ->rxm(qr/\A(\d+) .*\.t/xms)  # matches and auto extract all () in an array
    ->fsts                       # returns idx0 of inner array
    ->max                        # pick highest numbers - starts computation
    ->or(0);                     # max returns optional
                                 #   or(0) extracts or gives default value

# Now starts calculating the 10_000 items and prints them
$smaller->iter(sub($x) {
    say $x;
});
```

# Seq counting to 1 Billion

Try running: `examples/1bill.pl`

```perl
use Sq;
use Sq::Sig;
use Time::HiRes qw(time);

my $first  =
    Seq
    ->range(1,1_000_000_000)
    ->do_every(100_000, sub($num,$idx){ print "$num\n" });

my $second =
    Seq->range(1,1_000_000_000);

# this executes the subroutine and prints how long it took when finished.
Sq->bench->it(sub {
    print "Are those sequences lazy?\n";
    if ( equal($first,$second) ) {
        print "Yes, and they are the same!\n";
    }
    else {
        print "Yes, but not the same!\n";
    }
});
```

or: `t/Seq/11-lazy.t`

```perl
# 1 billion
my $big = Seq->range(1,1_000_000_000);

# two different branches of 1 billion
my $double  = $big->map(sub($x) { $x * 2  });
my $squared = $big->map(sub($x) { $x * $x });

# zip those together
my $zipped = Seq::zip($double, $squared);

# only take(10) elements from it.
my $only10 = $zipped->take(10);

# compare
is(
    $only10,
    seq {
        [  2,   1 ],
        [  4,   4 ],
        [  6,   9 ],
        [  8,  16 ],
        [ 10,  25 ],
        [ 12,  36 ],
        [ 14,  49 ],
        [ 16,  64 ],
        [ 18,  81 ],
        [ 20, 100 ]
    },
    'build something small');
```

# EXPORT

It exports the following functions by default:

| Category    | Functions                        |
|----         | ---                              |
| Creation    | sq key Some None Ok Err new type array hash |
| Functions   | fn multi static with_dispatch type_cond record |
| Equality    | equal                            |
| OBJ         | call                             |
| Scope       | assign lazy                      |
| Helpers     | id fst snd dump dumps            |
| Comparision | by_num by_str by_stri            |
| Type-checks | is_num is_str is_array is_hash is_seq is_opt is_result is_ref is_regex is_type |

# SYNOPSIS

Why Sq?

Because I didn't liked the way that Perl and many other languages evolved. This crazy stuff and automatic "crying" that everything not object-oriented must be
bad is horrible.

So I just wanted another direction.

I just read all beginner books of Perl. Had the Perl Bible. Perl
Best Practices, Object-Oriented Perl, 2-3 Catalyst Books. Developers Testing,
Advanced Perl Programming 1st and 2nd Edition. Algorithms with Perl.
Netzwerk Programmiern mit Perl (Network Programming with Perl. Don't know
if there was an english book) and some others.

The most important one was [Higher-Order Perl](https://hop.perl.plover.com/) (HOP) in 2008.

I guess it completely shaped how I thought about programming and found a better
way of writing programs.

As I actually wanted todo Game Development I learned C# with Unity. Again C#
was a nightmare. Coming from Perl with Moose, C# looked horrible outdated. But
it was faster.

I then learned F# as after HOP i wanted to learn more deeper about functional
programming. I mostly learned F# from [F# For Fun and Profit](https://fsharpforfunandprofit.com/)

I really liked F# and will continue using it to make a game in the future.

Still I am loving and using Perl nearly 20 years. Working on a Linux machine
with Perl. You can do a lot of stuff like automation or other file/text
processing that are just easier compared to other languages.

I worked as a proffesional Perl developer in the past, did web-development,
database, linux-administration and wrote and automated a full CMS with all kind of
auto-deployment, database upgrades, all written in Perl. I did my
job so good that the software was finished and I basically got fired.

`Sq` is now somewhat my own system to help me solve the typical problems I have.
I could have picked F# as I really liked the language. But working with F#
is, the funny part, too slow.

My complete test-suite with over 2000 tests runs in under one real-time second.
`prove -lrj 24`. And consider it must first parse and compile every single
file. It starts 42+ test files in parallel.

In that time I didn't get a simple "Hello, World!" printed in F#. It takes
around 3 seconds to start.

As I knew Perl the best, I choosed to write it in Perl.

Otherwise F# is fast, but I usually didn't liked how complex the community
tries to solve problems. Even APIs seems over complicated. I guess that
is what dynamic-typed developers better do. They know better how an API
must be, because you must remember it. Usually the IDE doesn't help you.

I know it because I basically worked most of my time just with Geanny and Perl.
Syntax Highlithing is all we had back then. But you know. You become faster this
way.

Anyway `Sq` is my take on programming in a procedural, LISP-like, dynamic-typed
ML language.

See the [API overview](lib/Sq/API.pod)

# Implemented so Far

Some interesting things like a Type-System, Equality, Parser, Testing-System
and a whole feature rich Array, Hash and lazy sequence is already solved to a
great part. Still not complete. It also offers loadable Signatures.

The API itself is not fixed, means some stuff is very likely to change.

I wouldn't recommend this module at the moment to build something critical
unless you are fine that you very likely need fixes to make code
working again.

In the next time I guess I will create more complex tests. So not just tests
that covers all code paths. More actual useful ones. This way it also
can be seen how things are solved.

But I already write my own console apps with it and try to improve those.
So somehow `Sq` is practical. I try to solve problems with it, and change
things when they seems to make more sense in practice over theory.

* [Sq::Type](lib/Sq/Manual/Type/00-Intro.pod)
* [Sq::Signature](lib/Sq/Manual/Type/01-Signature.pod)
* [Sq::Parser](lib/Sq/Manual/Parser/00-intro.pod)
* [Sq::Equality](lib/Sq/Equality.pm) implements `equal` function and add methods
* [Sq::Fs](lib/Sq/Fs.pod) file-system operations
* [Sq::Evaluator](lib/Sq/Evaluator) Implements functions to eval data-structures. See [Type](t/Evaluator/00-type.t) and [Parser](t/Evaluator/01-parser.t)
* [Sq::Test](lib/Sq/Test.pm) minimal Test-Suite that is already used to test Sq itself
* [Sq::Dump](lib/Sq/Dump.pm) implements `dump` and `dumps` and add methods
* [Sq::Collections::Seq](lib/Sq/Collections/Seq.pod)
* [Sq::Collections::Array](lib/Sq/Collections/Array.pod)
* [Sq::Collections::Hash](lib/Sq/Collections/Hash.pod)
* [Sq::Core::Option](lib/Sq/Core/Option.pod)
* [Sq::Core::Result](lib/Sq/Core/Result.pod) (Partially implemented)
* [Sq::Collections::Queue](lib/Sq/Collections/Queue.pm)
* [Sq::Collections::List](lib/Sq/Collections/List.pm)
* [Sq::Collections::Heap](lib/Sq/Collections/Heap.pod)

# SUPPORT

Development project is on Github [Perl-Sq](https://github.com/DavidRaab/Sq)

You can find documentation for this module with the perldoc command.

    perldoc Sq

You can also look for information at [my Blog on Perl Sq](https://davidraab.github.io/tags/sq/)

# AUTHOR

David Raab, **davidraab83 at gmail.com**

# LICENSE AND COPYRIGHT

This software is Copyright (c) by David Raab.

This is free software, licensed under:

  The MIT (X11) License
