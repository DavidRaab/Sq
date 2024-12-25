#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Benchmark qw(cmpthese);

cmpthese(-1, {
    mod => sub {
        my $b;
        for my $x ( 1 .. 1_000 ) {
            $b = $x % 2 == 0;
        }
    },
    binary => sub {
        my $b;
        for my $x ( 1 .. 1_000 ) {
            $b = $x & 1 == 0;
        }
    },
});
