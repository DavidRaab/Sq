#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Getopt::Long::Descriptive;
use POSIX qw(round);
use Sq;

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['help|h', 'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

# "Theoretical" finite sequence of prime numbers
# "theoretical" because we have only have 64 bit float
my $primes =
    Seq
    ->unfold(2, sub($x){ $x, $x+1   })
    ->filter(sub($x) { is_prime($x) });


print "Primes smaller 10_000\n";
$primes
->take_while(sub($x) { $x < 10_000 })
->iter(sub($prime) {
    print $prime, " ";
});
print "\n";


sub is_prime($x) {
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
            if ( is_prime($maybe_prime) ) {
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
}
