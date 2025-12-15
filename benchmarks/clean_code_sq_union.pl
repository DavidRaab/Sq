#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark;

# This is how you would code the problem in an ML-like language. Also
# how I prefer to solve it. The Pure Perl versions also somewhat comes
# close to those. The idea of a simple Array and the first element a
# string distinguish the types is somehow LISP-Like. A hash with a type
# is maybe more like an C-struct. But all of them have in common that
# the are data and have a field to distinguish them.
#
# At the moment, this code is the slowest, this is because of its
# implementation that is very flexible, but cost much performance.
#
# You actually can create multiple unions, and all unions are considered
# equal as long the cases and the types are the same. It's a structural
# approach. match() also check if all cases are handled and there are
# type-checks added when you create data.

# $shape contains a type definition
my $shape = union(
    Square    => ['num'],
    Rectangle => [tuple => ['num'],['num']],
    Triangle  => [tuple => ['num'],['num']],
    Circle    => ['num'],
);
# $shape->install()
# creates a Constructor function for each case. So Square(), Rectangle()
# Triangle() and Circle() are created after this. Those function do a
# tpye-checking when you create them. Those cases contain a match() function
# to pattern match. In the match() function you must provide a branch for
# every case, otherwise the code throws an exception.
$shape->install;

# An idea I have is that those type-check for creation and checking
# all available cases in pattern-matching are only available when
# signatures are active. So with signature you ensure that code correctly
# handles all cases, and without signature you then get higher performance.
# But this is not implemented yet. Also don't know if i change Union. So instead
# of a type-variable you register them globally. This also can open some
# more optimizations.

# Shape -> Area
sub area($shape) {
    return $shape->match(
        Square    => sub ($side)   { $side    * $side           },
        Rectangle => sub ($wh)     { $wh->[0] * $wh->[1]        },
        Triangle  => sub ($wh)     { $wh->[0] * $wh->[1]        },
        Circle    => sub ($radius) { $radius ** 2 * 3.141592654 },
    );
}

# [Shape] -> Area
sub totalArea($shapes) {
    return $shapes->sum_by(\&area);
}

my $shapes;
my $time = timeit(10, sub {
    $shapes = Array->init(10_000, sub {
        my $rng = int rand 4;
        return
            $rng == 0 ? Square(2) :
            $rng == 1 ? Rectangle([2,3]) :
            $rng == 2 ? Triangle( [3,1]) :
            Circle(3);
    });
});
printf "Creation 10K: %s\n", timestr($time);

my $area = 0;
$time = timeit(100, sub { $area = totalArea($shapes) });
printf "Area1 10K: %f %s\n", $area, timestr($time);

__END__
Creation 10K:  0 wallclock secs ( 0.18 usr +  0.00 sys =  0.18 CPU) @ 55.56/s (n=10)
Area1 10K: 102642.896705  1 wallclock secs ( 0.90 usr +  0.00 sys =  0.90 CPU) @ 111.11/s (n=
