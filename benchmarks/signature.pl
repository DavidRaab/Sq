#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Type;
use Sq::Signature;
use Types::Standard qw( ArrayRef CodeRef Any );
use Params::ValidationCompiler qw( validation_for );
use Benchmark qw(cmpthese);

# A Benchmark at the moment to compare a version without any type-checks at all (bsearch)
# then the same function with Sq::Signature added (bsearch_sq)
# And a version using Params::ValidationCompiler (bsearch_pvc)
#
# at the moment the sq version is the slowest. I expected that because Sq::Signature
# is not written with performance in mind and no optimization is done at the moment.
# But it's okay this way, because the whole idea of Sq::Signature is that you just
# temporarily add it, for example in debuging/testing to find errors, and once
# found you disable it again.
#
# So somewhat you will get a slower version when Sq::Signature is active. But
# once disabled you get the performance of bsearch() (the fastest version).
#
# Still in the future performance is still a concern and it will be improved,
# but i also expect that the internal way how Sq::Signature or in general how
# Sq::Type will work will completely change. At the moment it is written that it
# works.
#
# Performance is still a concern because Sq::Type is not just for function
# signature checking. For example you also can use it to validate JSON input
# data, or other kind of stuff that you later don't disable in your code and
# stays active all the time.

# Binary search with fixed arguments and no type-checking at all
sub bsearch($comparer, $data, $search) {
    my $start = 0;
    my $stop  = $data->$#*;

    # Avoid lexical scoped variable inside loop - makes code faster
    my ($index, $result, $diff) = (0,0,0);

    # We set $a and $b because our comparer function use this values
    local $a = $search;
    local $b = 0;

    while ( $start <= $stop ) {
        # compute index to check
        $diff  = ($stop - $start) / 2;
        $index = int ($start + $diff);

        # call comparer
        $b      = $data->[$index];
        $result = $comparer->();

        # when comparer returns -1, it says that $a is smaller than $b.
        # $a is what we search for and $b is the current indexed entry from array.
        # So whatever we search must between $start and $index and we need
        # to modify $stop.
        if ( $result < 0 ) {
            $stop  = $index - 1;
        }
        # the opposite. what we search for is between $index and $stop.
        # we modify $start to $index.
        elsif ( $result > 0 ) {
            $start = $index + 1;
        }
        # found entry
        else {
            return $index;
        }
    }

    # when entry does not exists
    return -1;
}

# Sq::Signature
sub bsearch_sq($comparer, $data, $search) {
    my $start = 0;
    my $stop  = $data->$#*;

    # Avoid lexical scoped variable inside loop - makes code faster
    my ($index, $result, $diff) = (0,0,0);

    # We set $a and $b because our comparer function use this values
    local $a = $search;
    local $b = 0;

    while ( $start <= $stop ) {
        # compute index to check
        $diff  = ($stop - $start) / 2;
        $index = int ($start + $diff);

        # call comparer
        $b      = $data->[$index];
        $result = $comparer->();

        # when comparer returns -1, it says that $a is smaller than $b.
        # $a is what we search for and $b is the current indexed entry from array.
        # So whatever we search must between $start and $index and we need
        # to modify $stop.
        if ( $result < 0 ) {
            $stop  = $index - 1;
        }
        # the opposite. what we search for is between $index and $stop.
        # we modify $start to $index.
        elsif ( $result > 0 ) {
            $start = $index + 1;
        }
        # found entry
        else {
            return $index;
        }
    }

    # when entry does not exists
    return -1;
}
# Actually output is t_int, but i choose t_any here because it is faster
# as comparing an integer. For Benchmarking this makes sense because the other
# modules don't check the return value of a function at all.
sig('main::bsearch_sq', t_sub, t_array, t_any, t_any);


# Params::ValidationCompiler
my $validator = validation_for(
    params => [
        { type => CodeRef  },
        { type => ArrayRef },
        { type => Any      },
    ],
);
sub bsearch_pvc {
    my ($comparer, $data, $search) = $validator->(@_);
    my $start = 0;
    my $stop  = $data->$#*;

    # Avoid lexical scoped variable inside loop - makes code faster
    my ($index, $result, $diff) = (0,0,0);

    # We set $a and $b because our comparer function use this values
    local $a = $search;
    local $b = 0;

    while ( $start <= $stop ) {
        # compute index to check
        $diff  = ($stop - $start) / 2;
        $index = int ($start + $diff);

        # call comparer
        $b      = $data->[$index];
        $result = $comparer->();

        # when comparer returns -1, it says that $a is smaller than $b.
        # $a is what we search for and $b is the current indexed entry from array.
        # So whatever we search must between $start and $index and we need
        # to modify $stop.
        if ( $result < 0 ) {
            $stop  = $index - 1;
        }
        # the opposite. what we search for is between $index and $stop.
        # we modify $start to $index.
        elsif ( $result > 0 ) {
            $start = $index + 1;
        }
        # found entry
        else {
            return $index;
        }
    }

    # when entry does not exists
    return -1;
}

# creates an array with 100_00 entries with ascending order and numbers skips of 1-2
my $array;
{
    my $current = 0;
    for ( 1 .. 100_000 ) {
        push @$array, $current;
        $current = int( $current + 1 + rand(3) );
    }
}
say "Max: " , $array->[-1];

my $by_num = sub { $a <=> $b };
# Benchmark different solutions
cmpthese(-2, {
    bsearch => sub {
        for ( 1 .. 250 ) {
            my $idx1 = bsearch($by_num, $array,  25_000);
            my $idx2 = bsearch($by_num, $array,  50_000);
            my $idx3 = bsearch($by_num, $array, 150_000);
            my $idx4 = bsearch($by_num, $array, 200_000);
        }
    },
    bsearch_sq => sub {
        for ( 1 .. 250 ) {
            my $idx1 = bsearch_sq($by_num, $array,  25_000);
            my $idx2 = bsearch_sq($by_num, $array,  50_000);
            my $idx3 = bsearch_sq($by_num, $array, 150_000);
            my $idx4 = bsearch_sq($by_num, $array, 200_000);
        }
    },
    bsearch_pvc => sub {
        for ( 1 .. 250 ) {
            my $idx1 = bsearch_pvc($by_num, $array,  25_000);
            my $idx2 = bsearch_pvc($by_num, $array,  50_000);
            my $idx3 = bsearch_pvc($by_num, $array, 150_000);
            my $idx4 = bsearch_pvc($by_num, $array, 200_000);
        }
    },
});
