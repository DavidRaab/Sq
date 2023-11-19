#!perl
use 5.036;
use List::Util qw(reduce);
use Seq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float/;
use DDP;

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $id      = sub($x) { $x          };
my $add1    = sub($x) { $x + 1      };
my $double  = sub($x) { $x * 2      };
my $square  = sub($x) { $x * $x     };
my $is_even = sub($x) { $x % 2 == 0 };

my $fst     = sub($array) { $array->[0] };
my $snd     = sub($array) { $array->[1] };

#----------

# lazy
my $data1 =
    Seq->wrap(
        Seq->wrap(1,1),
        Seq->wrap(2,3,5,8,13),
    );

# non-lazy
my $data2 =
    [
        [1,1],
        [2,3,5,8,13],
    ];

# non lazy implementation of flatten
sub flatten($aoa) {
    my @flattened;
    for my $outer ( @$aoa ) {
        for my $inner ( @$outer ) {
            push @flattened, $inner;
        }
    }
    return \@flattened;
};

# test both calling styles
is(
    Seq::flatten($data1)->to_array,
    flatten($data2),
    'flatten fp - non-lazy');

is(
    $data1->flatten->to_array,
    flatten($data2),
    'flatten oo - non-lazy');

## Implementing bind with map->flatten
my $bind = sub($s, $f) {
    return $s->map($f)->flatten;
};

# check if bind is same as map->flatten
is(
    $data1->bind($id)->to_array,
    $bind->($data1, $id)->to_array,
    'bind implemented with map and flatten');

done_testing;