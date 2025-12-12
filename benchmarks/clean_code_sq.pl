#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark;

# There is no real "Sq" version. The idea of Sq is to just use perl
# default data-structures as much as possible. So all the Pure Perl versions
# are basically how I recommend how to code in Sq. But we can use some
# Sq "language features". This obviously make the code somewhat slower
# to a pure perl version. Every framework/library that adds abstraction
# and let's you write stuff with less code over the pure language usually
# comes with performance degradion.
#
# But when it comes to coding, this is basically the way i recommend, or
# probably would write the problem in Sq. So i stick to.
#
# + Use a Hash for data, and bless them
# + Create area() function to calculate area of a Shape
# + Use Array::sum_by() with area() to generate totalArea
# + Use Array->init for array creation

sub square($side) {
    hash(type => 'Square', side => $side)
}
sub rectangle($width,$height) {
    hash(type => 'Rectangle', width => $width, height => $height)
}
sub triangle($base,$height) {
    hash(type => 'Triangle', base => $base, height => $height)
}
sub circle($radius) {
    hash(type => 'Circle', radius => $radius)
}

sub area($shape) {
    my $type = $shape->{type};
    if    ( $type eq 'Square'    ) { $shape->{side}  * $shape->{side}         }
    elsif ( $type eq 'Rectangle' ) { $shape->{width} * $shape->{height}       }
    elsif ( $type eq 'Triangle'  ) { $shape->{base}  * $shape->{height} * 0.5 }
    elsif ( $type eq 'Circle'    ) { $shape->{radius} ** 2 * 3.141592654      }
    else  { die "Unknown type: $type" }
}

sub totalArea($shapes) {
    return $shapes->sum_by(\&area);
}

# This is nice to write, but also comes with it's price. with sum_by(\&area)
# we just call one function for every shape. and the function directly computes
# the area.
#
# This dispatch version has somewhat nice syntax and you see the dispatch,
# but every dispatch must be done through a hash-lookup + calling an additional
# function for every branching logic. This technically is the same as
# the OO version. At least when it comes to performance. Why?
#
# Consider what   `$shape->area()`   does. First it must determine the type. In
# Perl done through blessing. The $shape contains the information of the
# blessed package. For example it could be `Shape::Circle` then it knows it
# must call   `Shape::Circle::area($shape)`.
#
# This kind of dispatch must be done in every OO language and whenever you
# call some method on an object.
#
# The only difference in this version is that you provide the dispatch for
# all types in a single function.
sub totalArea2($shapes) {
    return $shapes->sum_by(dispatch(key 'type', {
        Square    => sub($shape) { $shape->{side}  * $shape->{side}         },
        Rectangle => sub($shape) { $shape->{width} * $shape->{height}       },
        Triangle  => sub($shape) { $shape->{base}  * $shape->{height} * 0.5 },
        Circle    => sub($shape) { $shape->{radius} ** 2 * 3.141592654      },
    }));
}

my $shapes;
my $time = timeit(10, sub {
    $shapes = Array->init(10_000, sub {
        my $rng = int rand 4;
        return
            $rng == 0 ? square(2) :
            $rng == 1 ? rectangle(2,3) :
            $rng == 2 ? triangle(3,1) :
            circle(3);
    });
});
printf "Creation 10K: %s\n", timestr($time);

my $area = 0;
$time = timeit(100, sub { $area = totalArea($shapes) });
printf "Area1 10K: %f %s\n", $area, timestr($time);

$area = 0;
$time = timeit(100, sub { $area = totalArea2($shapes) });
printf "Area2 10K: %f %s\n", $area, timestr($time);