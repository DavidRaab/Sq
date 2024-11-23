#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);

printf "Benchmarking: range(1, 10_000)\n";
cmpthese(-1, {
    seq   => sub { Seq  ->range(1, 10_000)->to_array },
    array => sub { Array->range(1, 10_000)           },
});

printf "\nBenchmarking: range(1, 0.5, 5_000) \n";
cmpthese(-1, {
    seq   => sub { Seq  ->range_step(1, 0.5, 5_000)->to_array },
    array => sub { Array->range_step(1, 0.5, 5_000)           },
});

printf "\nBenchmarking: range(1, 10_000)->take(100)\n";
cmpthese(-1, {
    seq   => sub { Seq ->range(1, 10_000) ->to_array(100) },
    array => sub { Array->range(1, 10_000)->take(100)     },
});
