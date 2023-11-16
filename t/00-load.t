#!perl
use 5.036;
use Seq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa/;

diag( "Testing Seq $Seq::VERSION, Perl $], $^X" );
is($Seq::VERSION, number_ge("0.001"), 'Check minimum version number');

# Some values, functions, ... for testing
my $range  = Seq->range(1, 10);

my $double  = sub($x) { $x * 2      };
my $is_even = sub($x) { $x % 2 == 0 };

is($range, D(),                 'range returns something');
is($range, check_isa('Seq'),    'returns a Seq');
is($range->to_array, [1 .. 10], 'to_array');
is($range->to_array, [1 .. 10], 'calling to_array twice still returns the same');
is(
    $range->map($double)->to_array,
    [2,4,6,8,10,12,14,16,18,20],
    'map');

is(
    $range->filter($is_even)->to_array,
    [2,4,6,8,10],
    'filter');

is(
    $range->take(5)->to_array,
    [1..5],
    'take');

done_testing;