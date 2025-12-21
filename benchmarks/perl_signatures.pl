#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq; # -sig => 1;

# This shows a classical synthetical Benchmark and why Benchmarking
# can be hard.
#
# I wanted to know how much overhead Perl's signature feature. At least
# the signature feature adds some runtime code to check it's arguments.
# So i created two add4 versions. One with signature, the other without.
#
# It showed that the add4 version with signatures was about 15% faster.
#
# The wrong conclusion of this would be that signatures makes all your
# function 15% slower. Understand it like this, just to pick some
# imaginary numbers.
#
# with signature the signature maybe took 15ns, and adding 4 numbers
# took 85ns. So you end up that the version with signatures is slower
# around 15%.
#
# But rarely do we have such simple functions. When we have a function
# like mapp() that creates a whole new array, goes through multiple values
# and calls a function for each value. Well then maybe the function
# took 10.000ns to run. And the signature still only took 15ns.
#
# So overall the performance of signature don't matter. This is a classical
# case for "Premature Optimization". Not only that. Creating correct Benchmarks
# is hard. As a general advice we always should create Benchmarks on "Real Data".
#
# It even can be that you provide code and optimize code that runs faster
# against your synthetical benchmark, maybe you hardcoded your data and
# you run a thousand times against the exact data. Only to find out that
# when you run your code against real data you need to process it turns out
# to be slower.
#
# So always be aware of Synthetical Benchmark. Correct Benchmarks can be
# hard.

sub add4s($x,$y,$z,$w) { $x + $y + $z + $w }
sub add4 {
    my ($x, $y, $z, $w) = @_;
    $x + $y + $z + $w;
}
sub maps($array, $f) {
    bless([map { $f->($_) } @$array], 'Array');
}
sub mapp {
    my ($array, $f) = @_;
    bless([map { $f->($_) } @$array], 'Array');
}

print "Benchmarking add4\n";
my $nums = Sq->rand->int(1,1E6)->take(4 * 10_000)->chunked(4)->to_array;
Sq->bench->compare(-1, {
    pure => sub {
        for my $args ( @$nums ) {
            add4(@$args);
        }
    },
    signature => sub {
        for my $args ( @$nums ) {
            add4s(@$args);
        }
    }
});

print "\nBenchmarking map\n";
my $add1 = sub { $_[0] + 1 };
Sq->bench->compare(-1, {
    mapp => sub {
        for my $args ( @$nums ) {
            mapp($args, $add1);
        }
    },
    maps => sub {
        for my $args ( @$nums ) {
            maps($args, $add1);
        }
    }
});

__END__
Benchmarking add4
           Rate signature      pure
signature 710/s        --      -14%
pure      830/s       17%        --

Benchmarking map
      Rate maps mapp
maps 171/s   --  -1%
mapp 172/s   1%   --