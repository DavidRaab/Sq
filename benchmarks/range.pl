#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;

print "When to use a sequence?\n\n";

# This shows some reasons to use Seq or not.
#
# First i just tested initialization. Basically just calling Array->range
# vs Seq->range. But with just this benchmark a Seq would be faster because
# it wouldn't do anything. So i added ->to_array() to the Seq call
# to test creation of an array from a sequence.
#
# Still this seemed a little bit unfair, because when just throwing values
# away or not using them, this is the advantage of using a Seq over an Array.
# Because a Sequence is lazy evaluated and only needs to compute what it
# needs to compute.
#
# So i added a ->map call to both versions. Now both versions also use the
# created initialized range. In the case of an Array it means
# the ->range() call creates an array, and the ->map() creates a whole new
# array. On the other hand the Seq code only creates one single Array
# and does the same computations.
#
# Typically adding more and more function transformations can make Array
# slower and Seq faster. Relative to each other. Because in the case of
# Array new fully arrays have to be created, on the other side a sequence
# basically does a full calculation for every single element and then just
# creates a single array. This is seen when three ->map calls are done.
# In the first two examples an Array is ~50% faster. But doing three
# ->map() calls and the Array code is only ~25% faster.
#
# The Array code then has to create 4 intermediate arrays. The sequence
# just creates one.
#
# The biggest advantage of a sequence is surely when you don't need to
# iterate all values. For example mapping and retrieving just 100 elements
# out of 10_000 makes the sequence over 600x faster.

sub add1($x) { $x + 1 }

print "Range 1-1Mio fetching no elements.\n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range(1, 1_000_000) },
    array => sub { Array->range(1, 1_000_000) },
});

print "\nRange 1-1Mio generating 100 elements Array\n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range(1, 1_000_000)->to_array(100) },
    array => sub { Array->range(1, 1_000_000)->take(100)     },
});

print "\nRange 1-1Mio generating 1Mio Array\n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range(1, 1_000_000)->to_array },
    array => sub { Array->range(1, 1_000_000)           },
});

printf "\nRange 1-1M map every element, then convert all to array\n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range(1, 1_000_000)->map(\&add1)->to_array },
    array => sub { Array->range(1, 1_000_000)->map(\&add1)           },
});

printf "\nRange 1-1M map every element, only pick 100\n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range(1, 1_000_000)->map(\&add1)->to_array(100) },
    array => sub { Array->range(1, 1_000_000)->map(\&add1)->take(100)     },
});

printf "\n3x ->map(\&add1) convert all to array\n";
Sq->bench->compare(-3, {
    seq   => sub { Seq  ->range(1, 1_000_000)->map(\&add1)->map(\&add1)->map(\&add1)->to_array },
    array => sub { Array->range(1, 1_000_000)->map(\&add1)->map(\&add1)->map(\&add1)           },
});

printf "\n3x ->map(\&add1) generate 100 elements array\n";
Sq->bench->compare(-3, {
    seq   => sub { Seq  ->range(1, 1_000_000)->map(\&add1)->map(\&add1)->map(\&add1)->to_array(100) },
    array => sub { Array->range(1, 1_000_000)->map(\&add1)->map(\&add1)->map(\&add1)->take(100)     },
});

__END__
When to use a sequence?

Range 1-1Mio fetching no elements.
           Rate    array      seq
array    27.3/s       --    -100%
seq   2075800/s 7611167%       --

Range 1-1Mio generating 100 elements Array
         Rate   array     seq
array  27.3/s      --   -100%
seq   78914/s 289250%      --

Range 1-1Mio generating 1Mio Array
        Rate   seq array
seq   10.8/s    --  -60%
array 27.3/s  153%    --

Range 1-1M map every element, then convert all to array
        Rate   seq array
seq   4.59/s    --  -31%
array 6.60/s   44%    --

Range 1-1M map every element, only pick 100
         Rate   array     seq
array  6.67/s      --   -100%
seq   38059/s 570789%      --

3x ->map(&add1) convert all to array
        Rate   seq array
seq   2.02/s    --  -23%
array 2.63/s   30%    --

3x ->map(&add1) generate 100 elements array
         Rate   array     seq
array  2.64/s      --   -100%
seq   18038/s 683106%      --
