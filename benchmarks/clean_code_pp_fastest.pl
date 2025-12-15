#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Benchmark;

# Fastest version. Improvement that was descibed in *_pp_hash2.pl are done
# here.
# This kind of optimization are only possible once something "completed".
# In this case it means you have those four shapes and you know that there
# won't be a new one.
# Otherwise you can use an Array and use an enum-like type to distinguish.
# But doesn't mean every shape is defined by two values.

# Build something like an enum
my ($Square,$Rectangle,$Triangle,$Circle) = (0,1,2,3);

sub square($side)             { [$Square,    $side,   $side  ] }
sub rectangle($width,$height) { [$Rectangle, $width,  $height] }
sub triangle($width,$height)  { [$Triangle,  $width,  $height] }
sub circle($radius)           { [$Circle,    $radius, $radius] }

sub totalArea(@shapes) {
    state @table = (1,1,0.5,3.141592654);
    my $accum = 0;
    for my $shape ( @shapes ) {
        $accum += $table[$shape->[0]] * $shape->[1] * $shape->[2];
    }
    return $accum;
}

my @shapes;
my $time = timeit(500, sub {
    @shapes = ();
    for ( 1 .. 10_000 ) {
        my $rng = int rand 4;
        my $shape;
        if ( $rng == 0 ) {
            push @shapes, square(2);
        }
        elsif ( $rng == 1 ) {
            push @shapes, rectangle(2,3);
        }
        elsif ( $rng == 2 ) {
            push @shapes, triangle(3,1);
        }
        else {
            push @shapes, circle(3);
        }
    }
});
printf "Creation 10K\n%s\n", timestr($time);

my $area = 0;
$time = timeit(1000, sub {
    $area = totalArea(@shapes);
});
printf "Area 10K: %f\n%s\n", $area, timestr($time);

__END__
Creation 10K
 1 wallclock secs ( 1.27 usr +  0.00 sys =  1.27 CPU) @ 393.70/s (n=500)
Area 10K: 100427.228408
 1 wallclock secs ( 0.93 usr +  0.00 sys =  0.93 CPU) @ 1075.27/s (n=1000)
