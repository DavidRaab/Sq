package Sq::Bench;
use 5.036;
use Sq;

sub it($, $f) {
    require Benchmark;
    my $bench = Benchmark::timeit(1, $f);
    print Benchmark::timestr($bench), "\n";
    return $bench;
}

sub compare($time, $subs) {
    require Benchmark;
    return Benchmark::cmpthese($time, $subs);
}

1;