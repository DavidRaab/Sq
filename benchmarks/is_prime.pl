#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

# This function is a copy of Sq->math->is_prime and is tested in Sq.
sub is_prime_a($x) {
    state @primes = (
        2,   3,  5,  7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
        59, 61, 67, 71, 73, 79, 83, 89, 97, 101
    );
    my $max = int sqrt($x);

    # if last prime number is smaller than maximum, then @primes must be expanded
    # to work correctly
    if ( $primes[-1] < $max ) {
        my $maybe_prime = $primes[-1] + 1;
        while (1) {
            if ( __SUB__->($maybe_prime) ) {
                push @primes, $maybe_prime;
            }
            last if $primes[-1] > $max;
            $maybe_prime++;
        }
    }

    for my $prime ( @primes ) {
        return 1 if $x == $prime;
        return 0 if (($x % $prime) == 0);
        last if $prime > $max;
    }

    return 1;
};

sub is_prime_b($x) {
    # These lines are added. With a binary-and check we check if the number is
    # even and immediately return 0 if it is a even number, so it cannot be
    # prime. Except 2, that is a prime.
    return 1 if $x == 2;
    return 0 if ($x & 1) == 0;
    state @primes = (
        2,   3,  5,  7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
        59, 61, 67, 71, 73, 79, 83, 89, 97, 101
    );
    my $max = int sqrt($x);

    # if last prime number is smaller than maximum, then @primes must be expanded
    # to work correctly
    if ( $primes[-1] < $max ) {
        my $maybe_prime = $primes[-1] + 1;
        while (1) {
            if ( __SUB__->($maybe_prime) ) {
                push @primes, $maybe_prime;
            }
            last if $primes[-1] > $max;
            $maybe_prime++;
        }
    }

    for my $prime ( @primes ) {
        return 1 if $x == $prime;
        return 0 if (($x % $prime) == 0);
        last if $prime > $max;
    }

    return 1;
};

# Test if both functions are correct by checking that they return the same.
# This also has another effect. The first run from 1 .. 100_000 fills the
# state @primes array in both functions so when the Benchmark runs, it doesn't
# need to build the @primes array anymore.
my $failure;
for my $x ( 1 .. 100_000 ) {
    if ( is_prime_a($x) != is_prime_b($x) ) {
        $failure = $x;
        last;
    }
}
is($failure, undef, 'no failure');
done_testing;

# Benchmark
my $max = 100_000;
Sq->bench->compare(-1, {
    is_prime_a => sub {
        for my $x ( 2 .. $max ) {
            is_prime_a($x);
        }
    },
    is_prime_b => sub {
        for my $x ( 2 .. $max ) {
            is_prime_b($x);
        }
    },
});
