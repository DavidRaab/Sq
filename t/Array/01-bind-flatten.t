#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float/;

my $data1 =
    Array->new(
        Array->new(1,1),
        Array->new(2,3,5,8,13),
    );

# test both calling styles
is(
    Array::flatten($data1),
    $data1->flatten,
    'flatten');

## Implementing bind with map->flatten
my $bind = sub($s, $f) {
    return $s->map($f)->flatten;
};

# check if bind is same as map->flatten
is(
    $data1->bind(\&id),
    $bind->($data1, \&id),
    'bind implemented with map and flatten');

done_testing;