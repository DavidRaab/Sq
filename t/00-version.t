#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Test2::V0 qw(is diag done_testing number_ge);

diag( "Testing Sq $Sq::VERSION, Perl $], $^X" );
is($Sq::VERSION, number_ge("0.006"), 'Check minimum version number');

# check default imported functions
my $data = sq [
    [1,2,3],
    [4,5,6],
    [7,8,9],
];

is($data->map(call 'sum'),                  [6,15,24], 'call 1');
is($data->map(sub($array) { $array->sum }), [6,15,24], 'same without call');

is(
    $data->map(call 'map', sub($x) { $x+1 }),
    [
        [2,3,4],
        [5,6,7],
        [8,9,10],
    ],
    'call 2');

done_testing;
