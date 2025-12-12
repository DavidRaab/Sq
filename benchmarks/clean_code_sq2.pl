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
# to a pure perl version.

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

# dispatch() in a loop with many elements is not recommended. Only use this
# for high-level API dispatch.
sub totalArea1(@shapes) {
    my $accum = 0;
    for my $shape ( @shapes ) {
        dispatch($shape->{type},
            Square    => sub { $accum += $shape->{side}  * $shape->{side}   },
            Rectangle => sub { $accum += $shape->{width} * $shape->{height} },
            Triangle  => sub { $accum += $shape->{base}  * $shape->{height} * 0.5 },
            Circle    => sub { $accum += $shape->{radius} ** 2 * 3.141592654 },
        );
    }
    return $accum;
}

# Using dispatch() to create an anonymous function makes things better.
# But overall in a performance critic code, just use an if/elsif/else statement
sub totalArea2(@shapes) {
    my $accum = 0;
    my $area  = dispatch(key 'type', {
        Square    => sub($shape) { $accum += $shape->{side}  * $shape->{side}   },
        Rectangle => sub($shape) { $accum += $shape->{width} * $shape->{height} },
        Triangle  => sub($shape) { $accum += $shape->{base}  * $shape->{height} * 0.5 },
        Circle    => sub($shape) { $accum += $shape->{radius} ** 2 * 3.141592654 },
    });

    for my $shape ( @shapes ) {
        $area->($shape);
    }
    return $accum;
}

# totalArea3-5 expects an array and just use map->sum
sub area($shape) {
    my $type = $shape->{type};
    if    ( $type eq 'Square'    ) { $shape->{side}  * $shape->{side}         }
    elsif ( $type eq 'Rectangle' ) { $shape->{width} * $shape->{height}       }
    elsif ( $type eq 'Triangle'  ) { $shape->{base}  * $shape->{height} * 0.5 }
    elsif ( $type eq 'Circle'    ) { $shape->{radius} ** 2 * 3.141592654      }
    else  { die "Unknown type: $type" }
}

sub totalArea3($shapes) {
    return $shapes->map(\&area)->sum;
}

sub totalArea4($shapes) {
    return List::Util::sum0 map { area($_) } @$shapes;
}

sub totalArea5($shapes) {
    return $shapes->to_seq->map(\&area)->sum;
}

sub totalArea6($shapes) {
    return $shapes->sum_by(\&area);
}

# Array->init for creation of Array
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
$time = timeit(100, sub { $area = totalArea1(@$shapes) });
printf "Area1 10K: %f %s\n", $area, timestr($time);

$area = 0;
$time = timeit(100, sub { $area = totalArea2(@$shapes) });
printf "Area2 10K: %f %s\n", $area, timestr($time);

$area = 0;
$time = timeit(100, sub { $area = totalArea3($shapes) });
printf "Area3 10K: %f %s\n", $area, timestr($time);

$area = 0;
$time = timeit(100, sub { $area = totalArea4($shapes) });
printf "Area4 10K: %f %s\n", $area, timestr($time);

$area = 0;
$time = timeit(100, sub { $area = totalArea5($shapes) });
printf "Area5 10K: %f %s\n", $area, timestr($time);

$area = 0;
$time = timeit(100, sub { $area = totalArea6($shapes) });
printf "Area6 10K: %f %s\n", $area, timestr($time);

# Conclusion?
# Just use basic Perl data-structures. They are faster and usually you have
# less code. With Sq you just return blessed data-structures instead of normal
# perl ones. Obviously adding a blessing to a hash cost performance as
# not doing it. So it makes code slower. But by far not as slow as the
# full OO/Moose version.
#
# Interestingly doing a Array::map call that basically creates a full new array
# of 10_000 elements just with the area and than calling Array::sum to iterate
# that new Array is as fast/slow as the OO version with the method dispatch.
# Shows how much an impact OO has in general or in Perl.
#
# But Sq also offers a function like sum_by() that combines ->map->sum
# into one single operation. So in the OO/Moose version you have that long
# code, and still must write a for-each loop and recreate that sum_by logic
# yourself. In `Sq` you just use basic data-structures have mabe 10 times
# less code and you already get a single function you can call that does
# what you want.
#
# Sure you still can write a for-each loop yourself and not use sum_by()
# that still has some overhead as it needs to call a function for every
# element, instead of inlining code.