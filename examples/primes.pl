#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;

# "Theoretical" infinite sequence of prime numbers
# "theoretical" because we only have 64 bit float
# We could use Math::BigInt for bigger numbers (but its slower)
my $primes =
    Seq
    ->count_up(2)
    ->keep(sub($x) { Sq->math->is_prime($x) });

print "Primes smaller 10_000\n";
$primes->take_while(sub($x) { $x < 10_000 })->chunked(20)->iter(sub ($array) {
    print $array->join(" "), "\n";
});
print "\n";
