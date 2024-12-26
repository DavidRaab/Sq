#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;
use Sq::Type;
use Sq::Test;
use Benchmark qw(cmpthese);
use Devel::Size qw(total_size);

my @queue = 1 .. 100_000;
printf "Queue Size: %d\n", (total_size(\@queue));

for ( 1 .. 100_000 ) {
    push @queue, 1, 2;
    shift @queue;
    shift @queue;
    if ( $_ % 1000 == 0 ) {
        printf "Queue Size: %d\n", (total_size \@queue);
    }
}
