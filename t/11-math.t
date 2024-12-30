#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

my $primes =
    Seq
    ->count_up(2)
    ->filter(sub($x) { Sq->math->is_prime($x) })
    ->take(20);

is(
    $primes,
    seq { 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71 },
    'is_prime');

done_testing;
