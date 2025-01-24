package Sq::Bench;
use 5.036;
use Sq qw(static);
use Sq::Exporter;
our $SIGNATURE;
our @EXPORT = ();
use Benchmark qw(timestr timeit cmpthese);

static 'it', sub ($f) {
    my $bench = timeit(1, $f);
    print timestr($bench), "\n";
    return $bench;
};

static 'compare', sub($time, $subs) {
    return cmpthese($time, $subs);
};

1;