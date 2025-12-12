#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Benchmark;

# In this example i avoid calling the square(), rectangle(), ... functions
# in initialization and just directly create the arrays. The functions just
# serves as a "documentation". Sure they still can be called, but when
# high performance is needed it is usually best to avoid calling functions
# in loops to get most performance.
#
# This also has it's downside. If the data-structure changes, you must
# also change every function where you "inlined" the creation instead
# of relying to just call the function.

sub square($side)             { [Square    => $side]           }
sub rectangle($width,$height) { [Rectangle => $width, $height] }
sub triangle($base,$height)   { [Triangle  => $base, $height]  }
sub circle($radius)           { [Circle    => $radius]         }

sub totalArea(@shapes) {
    my $accum = 0;
    for my $shape ( @shapes ) {
        my $type = $shape->[0];
        if ( $type eq 'Square' ) {
            $accum += $shape->[1] * $shape->[1];
        }
        elsif ($type eq 'Rectangle' ) {
            $accum += $shape->[1] * $shape->[2];
        }
        elsif ($type eq 'Triangle' ) {
            $accum += $shape->[1] * $shape->[2] * 0.5;
        }
        else {
            $accum += $shape->[1] * $shape->[1] * 3.141592654;
        }
    }
    return $accum;
}

my @shapes;
my $time = timeit(10, sub {
    @shapes = ();
    for ( 1 .. 10_000 ) {
        my $rng = int rand 4;
        my $shape;
        if ( $rng == 0 ) {
            push @shapes, [Square => 2];
        }
        elsif ( $rng == 1 ) {
            push @shapes, [Rectangle => 2,3];
        }
        elsif ( $rng == 2 ) {
            push @shapes, [Triangle => 3,1];
        }
        else {
            push @shapes, [Circle => 3];
        }
    }
});
printf "Creation 10K: %s\n", timestr($time);

my $area = 0;
$time = timeit(100, sub {
    $area = totalArea(@shapes);
});
printf "Area 10K: %f %s\n", $area, timestr($time);