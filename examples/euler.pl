#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

# 1 + (1/1) + (1 / 1*2) + (1 / 1*2*3) + (1 / 1*2*3*4) + ...
my $euler_seq = Seq->unfold(0, sub($i){ return (1/fac($i)), $i+1 });

for my $iteration ( 1 .. 20 ) {
    my $euler = $euler_seq->take($iteration)->sum;
    printf "%2d -> %.15f\n", $iteration, $euler;
}

sub fac($n) {
    return 1 if $n == 0;
    my $result = 1;
    $result *= $_ for 1 .. $n;
    return $result;
}
