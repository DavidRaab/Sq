#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;
use Sq::Type;
use Sq::Test;
use Benchmark qw(cmpthese);
use Devel::Size qw(total_size);


my $q = Queue->new(1..100_000);
printf "Queue Size: %d\n", (total_size $q);

for ( 1 .. 100_000 ) {
    $q->add(1,2);
    $q->remove(2);
    if ( $_ % 1000 == 0 ) {
        printf "Queue Size: %d\n", (total_size $q);
    }
}

printf "Capacity: %d\n", $q->capacity;