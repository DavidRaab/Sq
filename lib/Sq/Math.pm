package Sq::Math;
use 5.036;
use Sq qw(static);

static is_prime => sub($x) {
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

static fac => sub($num) {
    return 1 if $num == 0 || $num == 1;
    my $result = 1;
    for my $x ( 2 .. $num ) {
        $result *= $x;
    }
    return $result;
};

# Expects an array of int
# For example starts with:
# [0,0,0,0]
static permute_count_up => sub($array) {
    my $idx = $array->$#* - 1;
    my $max = @$array - ($idx+1);

    UP:
    $array->[$idx]++;
    if ( $array->[$idx] > $max ) {
        $array->[$idx] = 0;
        $idx--;
        return if $idx < 0;
        $max = @$array - ($idx+1);
        goto UP;
    }
    return 1;
};

1;