#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;

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

printf "Benchmarking: range(1, 10_000)->map(\&add1)\n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range(1, 10_000)->map(\&add1)->to_array },
    array => sub { Array->range(1, 10_000)->map(\&add1)           },
});

printf "\nBenchmarking: range(1, 0.5, 5_000)->map(\&add1) \n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range_step(1, 0.5, 5_000)->map(\&add1)->to_array },
    array => sub { Array->range_step(1, 0.5, 5_000)->map(\&add1)           },
});

printf "\nBenchmarking 3x ->map(\&add1)->to_array\n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range(1, 10_000)->map(\&add1)->map(\&add1)->map(\&add1)->to_array },
    array => sub { Array->range(1, 10_000)->map(\&add1)->map(\&add1)->map(\&add1)           },
});

printf "\nBenchmarking: range(1, 10_000)->map(\&add1)->take(100)\n";
Sq->bench->compare(-1, {
    seq   => sub { Seq  ->range(1, 10_000)->map(\&add1)->to_array(100) },
    array => sub { Array->range(1, 10_000)->map(\&add1)->take(100)     },
});

__END__
Benchmarking: range(1, 10_000)->map(&add1)
       Rate   seq array
seq   453/s    --  -30%
array 649/s   43%    --

Benchmarking: range(1, 0.5, 5_000)->map(&add1)
       Rate   seq array
seq   342/s    --  -31%
array 499/s   46%    --

Benchmarking 3x ->map(&add1)->to_array
       Rate   seq array
seq   188/s    --  -19%
array 232/s   24%    --

Benchmarking: range(1, 10_000)->map(&add1)->take(100)
         Rate array   seq
array   592/s    --  -98%
seq   36202/s 6019%    --
