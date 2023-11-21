# NAME

Seq - A lazy sequence implementation

# SYNOPSIS

The Seq module provides a lazy sequence implementation that can be
executed multiple times. A sequence just represent a computation without
computing any values until they are requested.

Different to iterators they can be executed multiple times. A sequence
can somehow considered an immutable iterator.

At the moment Documentation is lacking, but the source-code is well-documented
including the test-files. Maybe you want to look at the test-files until
I have written more documentation. The API is not fully stable at the moment
and can be changed.

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
    ->choose( sub($x) { $x =~ m/\A(\d+) .* \.t\z/xms ? $1 : undef } )
    ->max;
```

# EXPORT

This modules does not export anything by default. But you can request the following
functions: id, fst, snd, key, assign

# CONSTRUCTORS

This module uses functional-programming as the main paradigm. Functions are
divided into constructors, methods and converters.

Constructor create a sequence. Methods operate on sequences and return
another new sequence. Converter transforms a sequence to some other data-type.

Methods are called methods for convenience, but no object-orientation is
involved. Perls OO capabilities are only used as a chaning mechanism.

Constructors must be called with the Package name. Functions that operate
on Sequences can either be called as a method or directly from the Package.

```perl
my $range =
    Seq
    ->wrap(1,2,3)
    ->append(Seq->wrap(4,5,6));
```

or

```perl
my $range =
    Seq::append(
        Seq->wrap(1,2,3),
        Seq->wrap(4,5,6),
    )
```

## $seq = Seq->empty()

Returns an empty sequence. Useful as an initial state or as a starting point.

```perl
Seq->empty->append( $another_seq )
```

## $seq = Seq->range($start, $stop)

Returns a sequence from $start to $stop. Range can also be backwards. $start
and $stop are inclusive.

```perl
Seq->range(1, 5); # 1,2,3,4,5
Seq->range(5, 1); # 5,4,3,2,1
Seq->range(1, 1); # 1
```

## $seq = Seq->wrap(...)

Just takes whatever you pass it to, and puts it in a sequence. This should be
your primarily way to create a sequence with values.

```perl
Seq->wrap(qw/Hello World/); # "Hello", "World"
Seq->wrap(1 .. 10);         # AVOID this, use Seq->range(1, 10) instead.
Seq->wrap(@array);
```

## $seq = Seq->concat(@sequences)

Takes multiple *Sequences* and returns a single flattened sequence.

```perl
# 1, 2, 3, 4, 5, 5, 4, 3, 2, 1
Seq->concat(
    Seq->range(1, 5),
    Seq->range(5, 1),
);
```

# MISSING DOC

Implemented, but not documented yet:

from_sub, unfold, init, range_step, from_list, from_array, from_hash

# METHODS

Implemented, but not documented yet:

append, map, bind, flatten cartesian, join, merge, select*, choose, mapi,
filter, take, skip, indexed, distinct, distinct_by, iter, do, rev

* will maybe change

# CONVERTERS

Implemented, but not documented yet:

fold, reduce, first, last, to_array, to_list, count, sum, sum_by, min,
min_by, min_by_str, max, max_str, max_by, max_by_str, str_join, to_hash,
group_by, find

# Github

Development project is on Github [Perl-Seq](https://github.com/DavidRaab/Seq)

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Seq

You can also look for information at [my Blog on Perl Seq](https://davidraab.github.io/tags/perl-seq/)

# AUTHOR

David Raab, C<< <davidraab83 at gmail.com> >>

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by David Raab.

This is free software, licensed under:

  The MIT (X11) License
