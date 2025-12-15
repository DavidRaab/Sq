#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Benchmark;

# Still using a Hash. But instead of the if/elsif we use a hash-table.
# This is so far the fastest version when it comes to benchmarking the
# totalArea() function.
#
# It is fastest because if-statements in loops are not the fastest and branching
# code makes things slower. OO-method-dispatch is also just branching code, just
# even more slower.
#
# It is fastest because we have a single calculation that is always the same.
# Here we even use a hash-table to dispatch the shape type to a number.
#
# We still could improve this version by using
#  + An Array for data
#  + An array for dispatching in totalArea()

sub square($side) {
    {type => 'Square',    width => $side,   height => $side}
}
sub rectangle($width,$height) {
    {type => 'Rectangle', width => $width,  height => $height}
}
sub triangle($width,$height) {
    {type => 'Triangle',  width => $width,  height => $height}
}
sub circle($radius) {
    {type => 'Circle',    width => $radius, height => $radius}
}

sub totalArea(@shapes) {
    state %table = (
        Square    => 1,
        Rectangle => 1,
        Triangle  => 0.5,
        Circle    => 3.141592654,
    );
    my $accum = 0;

    for my $shape ( @shapes ) {
        $accum += $table{$shape->{type}} * $shape->{width} * $shape->{height};
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
printf "Creation 10K: %s\n", timestr($time);

my $area = 0;
$time = timeit(1000, sub {
    $area = totalArea(@shapes);
});
printf "Area 10K: %f %s\n", $area, timestr($time);

__END__
Creation 10K:  2 wallclock secs ( 2.00 usr +  0.00 sys =  2.00 CPU) @ 250.00/s (n=500)
Area 10K: 98891.750702  2 wallclock secs ( 1.24 usr +  0.00 sys =  1.24 CPU) @ 806.45/s (n=1000)
