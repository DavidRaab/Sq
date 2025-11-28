package Sq::Math;
use 5.036;
use Sq qw(static);
use Sq::Exporter;
our $SIGNATURE = 'Sq/Sig/Math.pm';
our @EXPORT    = ();

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

# Expects an array of int. You always starts with an array with everything
# being zero. Like: [0,0,0,0]. Needs at least two [0,0] to work correctly.
#
### Description of how it works:
# The integer represents the indexes of an array you must remove from left
# to right to generate a permutation. For example [0,0,0,0] means you must
# remove four times in a row the first element to generate the first permutation.
#
# ['A', 'B', 'C', 'D'] -> []                   # remove 0
# ['B', 'C', 'D']      -> ['A']                # remove 0
# ['C', 'D']           -> ['A', 'B']           # remove 0
# ['D']                -> ['A', 'B', 'C']      # remove 0
# []                   -> ['A', 'B', 'C', 'D']
#
# This functions is basically just a counting algorithm. But instead that every
# digit has the same base, the base increases. The most right one always must
# be '0'. Then the 2nd last element either can be 0,1, then third last can be
# 0,1,2 and so on. The maximum value for 4 int is: [3,2,1,0]
# For 5 ints it is: [4,3,2,1,0]
#
# This function just counts the array up, and modify it's value (mutable). But
# then is used to generate a permutation. This way all permutations can be lazily
# generated as only the current "count-value" must be kept in memory.
#
# You also can read it up in Higher-Order Perl (You can get a free pdf copy
# on the website!)
static permute_count_up => sub($array) {
    my $idx = $array->$#* - 1;
    my $max = @$array - ($idx+1);

    UP:
    $array->[$idx]++;
    if ( $array->[$idx] > $max ) {
        $array->[$idx] = 0;
        $idx--;
        return 0 if $idx < 0;
        $max = @$array - ($idx+1);
        goto UP;
    }
    return 1;
};

# converts number to any other number system
static to_num_system => sub($str_places, $num) {
    my @places = split //, $str_places;
    my $count  = @places;

    $num = int($num);
    return $places[0] if $num == 0;

    my $result = "";
    while ( $num != 0 ) {
        my $mod   = $num % $count;
        my $digit = $places[$mod];
        $result .= $digit;
        $num -= $mod;
        $num  = $num / $count;
    }
    reverse $result;
};

static to_binary => sub($num) { sprintf "%b", $num };
static to_hex    => sub($num) { sprintf "%x", $num };

static divide_spread => sub($n,$d) {
    my @widths;
    # algorithm works like line drawing. We have an ideal, but this can be
    # a floating point. But we only can use integer. So we use $accum and
    # always add the floating point to it. The integer from that is saved,
    # and later subtracted from $accum. So sometimes the increase becomes one
    # more than ideal.
    my $ideal = $n / $d;
    my $accum = 0;
    my $value;
    for ( 1 .. $d ) {
        $accum += $ideal;
        $value  = int $accum;
        push @widths, $value;
        $accum -= $value;
    }
    # The problem with this approach is floating point crappness. Sometimes
    # at the end, the $accum could be 0.99999999987 whatever. So +1 is missing
    # at the very end. This is a hack. When $accum is greater 0.5, then last
    # value is increased. From tests so far, this seemed more correct.
    if ( $accum > 0.5 ) { $widths[-1]++ }
    bless(\@widths, 'Array');
};

static divide_symmetric => sub($n,$d) {
    my $base = int($n / $d);
    my $rest = $n % $d;

    # first we create an array with the base values
    my @result = ($base) x $d;

    # $rest says how much values in @result must be increment by 1.
    # we want to spread +1 symmetrically. So we need to calculate two positions
    # a $left and $right from the center. For example when $d was 6 we initialize
    # $left = 2; $right = 3

    # then we increment values inside @result from center as long we need
    my $left      = int(($d - 1) / 2);
    my $right     = $left + 1;
    my $increased = 0;
    while ($increased < $rest) {
        if ( $left >= 0 ) {
            $result[$left]++;
            $increased++;
        }
        if ( $right < $d && $increased < $rest ) {
            $result[$right]++;
            $increased++;
        }
        $left--;
        $right++;
    }

    return bless(\@result, 'Array');
};

1;