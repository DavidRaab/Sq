#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

my $data1 =
    Array->new(
        array(1,1),
        array(2,3,5,8,13),
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