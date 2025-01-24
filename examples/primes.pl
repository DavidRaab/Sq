#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Time::HiRes qw(sleep);
use Sq -sig => 1;

print "Sequence of primes runs twice to show cache().\n\n";

# "Theoretical" infinite sequence of prime numbers
# "theoretical" because we only have 64 bit float
# We could use Math::BigInt for bigger numbers (but its slower)
my $primes =
    Seq
    ->up(2)
    ->keep(sub($x) {
        sleep 0.001; # simulate sloweness for cache
        Sq->math->is_prime($x)
    })
    ->take_while(sub($x) { $x < 10_000 })
    ->cache;

Sq->bench->it(sub {
    print "Primes smaller 10_000\n";
    $primes->chunked(20)->iter(sub ($array) {
        print $array->join(" "), "\n";
    });
    print "\n";
});

Sq->bench->it(sub {
    print "Primes smaller 10_000\n";
    $primes->chunked(20)->iter(sub ($array) {
        print $array->join(" "), "\n";
    });
    print "\n";
});
