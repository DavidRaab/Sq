#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Benchmark;

# This uses an Hash instead of an Array to represent data. So instead of
#   ['Square', side => 3]
# we now have
#   {type => 'Square', side => 3 }
#
# a hash is obviously slower to an array. Both in creation and accesing fields
# compared to an array. But if you run the Benchmarks you will still see
# that in my opinion hashes are still fast, the performance doesn't degrade
# as some horrible C#/Java devs often think they do.
#
# Do you know that JavaScript has no real arrays and basically all arrays
# are hashes? Do you know that basically EVERY OBJECT is basically a
# hash? In pretty much every OO language there exist something like a
# virtual method dispatch. The idea of OO is that every class can overwrite
# a method. So at compile-time you basically don't know which method
# you need to call. So the method to be called must be found through a "lookup"
# what basically is a hash in the first-place.
#
# So watch those C# people closely when they tell you that everything must
# be obejcts, but never use Dictionaries, only Arrays, because Dictionaries
# are slow.

sub square($side) {
    {type => 'Square', side => $side}
}
sub rectangle($width,$height) {
    {type => 'Rectangle', width => $width, height => $height}
}
sub triangle($base,$height) {
    {type => 'Triangle', base => $base, height => $height }
}
sub circle($radius) {
    {type => 'Circle' => radius => $radius }
}

sub totalArea(@shapes) {
    my $accum = 0;
    for my $shape ( @shapes ) {
        my $type = $shape->{type};
        if ( $type eq 'Square' ) {
            $accum += $shape->{side} * $shape->{side};
        }
        elsif ($type eq 'Rectangle' ) {
            $accum += $shape->{width} * $shape->{height};
        }
        elsif ($type eq 'Triangle' ) {
            $accum += $shape->{base} * $shape->{height} * 0.5;
        }
        else {
            $accum += $shape->{radius} * $shape->{radius} * 3.141592654;
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
$time = timeit(100, sub {
    $area = totalArea(@shapes);
});
printf "Area 10K: %f %s\n", $area, timestr($time);