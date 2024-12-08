#!perl
use 5.036;
use Sq;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

# map
is(Some(1,2)     ->map(sub(@v) { Array::sum(\@v) }), Some(3), 'map 1');
is(Some(sq [1,2])->map(sub($a) { $a->sum         }), Some(3), 'map 2');
is(Some(1,2)     ->to_array->sum,                         3 , 'map 3');
is(Some(sq [1,2])->map(call 'sum'),                  Some(3), 'map 4');

# Creation of Some
is(Some(), None, 'Some without arguments is None');
is(
    Some(Some(1,2), Some(3,4)),
    Some(1,2,3,4),
    'its like working in list context');

is(
    Some(Some(1,2), Some(undef,4)),
    None,
    'one undef/None makes it invalid 1');

is(
    Some(Some(1,None), Some(3,4)),
    None,
    'one undef/None makes it invalid 2');

is(
    Some(1,2,None),
    None,
    'one undef/None makes it invalid 3');

is(
    Some(1,2,undef),
    None,
    'one undef/None makes it invalid 3');

is(
    Some(1,2,3, Some(4,5,6), Some(7), Some(Some(Some(8)))),
    Some(1..8),
    'always flattened with any depth');

# Option::or
is(scalar Some(1,2,3)->or(1,2),  1, 'or in scalar context 1');
is(scalar None->or(1,2),         1, 'or in scalar context 2');
is([Some(1,2,3)->or(1,2)], [1,2,3], 'or in list context 1');
is([None->or(1,2)],          [1,2], 'or in list context 2');

# is_some, is_none
is(Option::is_some(Some(1,2,3)), 1, 'is_some');
is(Option::is_none(None),        1, 'is_none 1');
is(Option::is_none(Some),        1, 'is_none 2');
is(Option::is_none(Some undef),  1, 'is_none 3');

# fold
is(
    Some(1,2,3)->fold(10, sub($x,$y,$z,$state) {
        $state + $x + $y + $z
    }),
    16,
    'fold');

is(
    Some(1,2,3)->fold_back(10, sub($state,$x,$y,$z) {
        $state + $x + $y + $z
    }),
    16,
    'fold_back');

is(
    Some(1,2,3)->fold_back(10, sub($state,@xs) {
        $state + Array::sum(\@xs)
    }),
    16,
    'fold_back');

# map2
is(
    Option::map2(Some(1,2), Some(3,4), sub($x,$y,$z,$w) {
        $x + $y + $z + $w
    }),
    Some(10),
    'map2 1');

is(
    Option::map2(Some(1,2), Some(3,4), sub(@args) {
        Array::sum(\@args)
    }),
    Some(10),
    'map2 2');

is(
    Some(1,2,3)->single->map(call 'sum'),
    Some(6),
    'single wraps multiple values into a single array');

is(
    Some([1,2,3])->single->map(call 'sum'),
    Some(6),
    'when it is a single value and array, does nothing');

is(
    Some(3)->single->map(call 'sum'),
    Some(3),
    'after single you always have a single array argument wrapped in option');

is(
    None->single->map(call 'sum'),
    None,
    'does nothing on None');

# get
is(
    scalar Some(1,2,3)->get,
    1,
    'get returns first element in scalar context');

is(
    [Some(1,2,3)->get],
    [1,2,3],
    'returns all elements in list context');

done_testing;
