#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

warn("# Testing Sq $Sq::VERSION, Perl $], $^X");
ok($Sq::VERSION >= "0.006", 'Check minimum version number');

# check default imported functions

# The `sq` function blesses the data-structure recursively and adds Array/Hash
# blessing to the structure. The only reason is that you can call some methods
# on it instead of only having a function interface. Those blessed Arrays/Hashes
# are otherwise just used as a plain Array/Hash as you wish.
#
# Also in `Sq` itself care is done that those blessed Arrays/Hashes are equal
# to the plain unblessed versions. Also the reverse is true. All functions are written
# that they also except plain unblessed Arrays/Hashes.
my $data = sq [
    [1,2,3],
    [4,5,6],
    [7,8,9],
];

is($data->map(call 'sum'),                  [6,15,24], 'call 1');
is($data->map(sub($array) { $array->sum }), [6,15,24], 'same without call');

is(
    Array::map([[1,2,3], [4,5,6], [7,8,9]], \&Array::sum),
    [6,15,24],
    'Array::map in functional style with unblessed arrays');

is(
    Array::map([[1,2,3], [4,5,6], [7,8,9]], call 'sum'),
    [6,15,24],
    'call now also supports unblessed Arrays/Hashes');

is(
    Option->filter_valid( $data->map(call 'max') ),
    [3,6,9],
    'calls max on each inner array');

is(
    $data->map(call 'map', sub($x) { $x+1 }),
    [
        [2,3,4],
        [5,6,7],
        [8,9,10],
    ],
    'call 2');

is(
    seq {1,2,3,undef,4,5,6},
    seq {1,2,3},
    'same with undef');

done_testing;
