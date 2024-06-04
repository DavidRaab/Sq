#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;

# Some values, functions, ... for testing
my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------

my $data = Hash->bless({
    foo => 1,
    bar => 10,
    baz => 5,
});

my $data2 = $data->map(sub($k,$v) {
    return ($k . 's'), $v * 2;
});

is($data,  {foo  => 1, bar  => 10, baz  =>  5}, '$data stays the same');
is($data2, {foos => 2, bars => 20, bazs => 10}, 'map');

my $data3 = $data->filter(sub($k,$v) {
    $k =~ m/\A b/xms ? 1 : 0;
});

is($data,  {foo  => 1, bar  => 10, baz  =>  5}, '$data stays the same');
is($data3, {bar => 10, baz => 5},               'filter');

is($data->fold(0, sub($state, $k, $v) { $state + $v }), 16, 'fold 1');
is($data->fold(1, sub($state, $k, $v) { $state + $v }), 17, 'fold 2');

is($data->count, 3, 'count');

done_testing;
