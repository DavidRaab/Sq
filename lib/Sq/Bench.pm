package Sq::Bench;
use 5.036;

sub it($, $f, $count=1) {
    require Benchmark;
    my $bench = Benchmark::timeit($count, $f);
    dumpw($bench);
    return $bench;
}

sub compare($time, $subs) {
    require Benchmark;
    return Benchmark::cmpthese($time, $subs);
}

1;