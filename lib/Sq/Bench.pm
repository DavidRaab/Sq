package Sq::Bench;
use 5.036;
use Benchmark qw(timestr timeit cmpthese);

sub it($, $f) {
    my $bench = timeit(1, $f);
    print timestr($bench), "\n";
    return $bench;
}

sub compare($, $time, $subs) {
    return cmpthese($time, $subs);
}

1;