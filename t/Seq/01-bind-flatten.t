#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

# lazy
my $data1 = seq {
    seq { 1,1 },
    seq { 2,3,5,8,13 },
};

# non-lazy
my $data2 = [
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
    $data1->bind(\&id),
    $bind->($data1, \&id),
    'bind implemented with map and flatten');

done_testing;