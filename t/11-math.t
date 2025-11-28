#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

# Here I also check the 'static' ability
# first, i use a normal function call. Then in the second example omiting
# the value, and a direct function call
{
    my $primes =
        Seq
        ->up(2)
        ->keep(sub($x) { Sq->math->is_prime($x) }) # wraped in lambda
        ->take(100);

    is(
        $primes,
        seq {
            2,   3,   5,   7,   11,  13,  17,  19,  23,  29,  31,  37,  41,  43,
            47,  53,  59,  61,  67,  71,  73,  79,  83,  89,  97,  101, 103, 107,
            109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181,
            191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263,
            269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
            353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433,
            439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521,
            523, 541
        },
        'primes 1'
    );
}

# without arguments is_prime returns function-reference to itself. 'static' assumes
# that zero or one argument was "no argument".
{
    my $primes =
        Seq
        ->up(2)
        ->keep(Sq->math->is_prime) # check without lambda
        ->take(100);

    is(
        $primes,
        seq {
            2,   3,   5,   7,   11,  13,  17,  19,  23,  29,  31,  37,  41,  43,
            47,  53,  59,  61,  67,  71,  73,  79,  83,  89,  97,  101, 103, 107,
            109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181,
            191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263,
            269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
            353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433,
            439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521,
            523, 541
        },
        'primes 2'
    );
}

{
    my $primes =
        Seq
        ->up(2)
        ->keep(Sq::Math::is_prime()) # Direct function-call
        ->take(100);

    is(
        $primes,
        seq {
            2,   3,   5,   7,   11,  13,  17,  19,  23,  29,  31,  37,  41,  43,
            47,  53,  59,  61,  67,  71,  73,  79,  83,  89,  97,  101, 103, 107,
            109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181,
            191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263,
            269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
            353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433,
            439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521,
            523, 541
        },
        'primes 3'
    );
}

{
    my $primes =
        Seq
        ->up(2)
        ->keep(Sq::Math->is_prime) # Direct function-call
        ->take(100);

    is(
        $primes,
        seq {
            2,   3,   5,   7,   11,  13,  17,  19,  23,  29,  31,  37,  41,  43,
            47,  53,  59,  61,  67,  71,  73,  79,  83,  89,  97,  101, 103, 107,
            109, 113, 127, 131, 137, 139, 149, 151, 157, 163, 167, 173, 179, 181,
            191, 193, 197, 199, 211, 223, 227, 229, 233, 239, 241, 251, 257, 263,
            269, 271, 277, 281, 283, 293, 307, 311, 313, 317, 331, 337, 347, 349,
            353, 359, 367, 373, 379, 383, 389, 397, 401, 409, 419, 421, 431, 433,
            439, 443, 449, 457, 461, 463, 467, 479, 487, 491, 499, 503, 509, 521,
            523, 541
        },
        'primes 4'
    );
}

{
    my $fac = Sq->math->fac;
    is($fac->(0),   1, 'fac 1');
    is($fac->(1),   1, 'fac 2');
    is($fac->(2),   2, 'fac 3');
    is($fac->(3),   6, 'fac 4');
    is($fac->(4),  24, 'fac 5');
    is($fac->(5), 120, 'fac 6');
}

{
    my $ns = Sq->math->to_num_system;

    # binary
    is($ns->("01", 0),           "0", 'to_binary 1');
    is($ns->("01", 1),           "1", 'to_binary 2');
    is($ns->("01", 2),          "10", 'to_binary 3');
    is($ns->("01", 3),          "11", 'to_binary 4');
    is($ns->("01", 4),         "100", 'to_binary 5');
    is($ns->("01", 64),    "1000000", 'to_binary 6');
    is($ns->("01", 128),  "10000000", 'to_binary 7');
    is($ns->("01", 256), "100000000", 'to_binary 8');
    is($ns->("01", 123),   "1111011", 'to_binary 9');

    # quads
    is($ns->("0123", 0),       "0", 'to_quad 1');
    is($ns->("0123", 1),       "1", 'to_quad 2');
    is($ns->("0123", 2),       "2", 'to_quad 3');
    is($ns->("0123", 3),       "3", 'to_quad 4');
    is($ns->("0123", 4),      "10", 'to_quad 5');
    is($ns->("0123", 64),   "1000", 'to_quad 6');
    is($ns->("0123", 128),  "2000", 'to_quad 7');
    is($ns->("0123", 256), "10000", 'to_quad 8');
    is($ns->("0123", 123),  "1323", 'to_quad 9');

    # octal
    is($ns->("01234567", 0),     "0", 'to_oct 1');
    is($ns->("01234567", 1),     "1", 'to_oct 2');
    is($ns->("01234567", 2),     "2", 'to_oct 3');
    is($ns->("01234567", 3),     "3", 'to_oct 4');
    is($ns->("01234567", 4),     "4", 'to_oct 5');
    is($ns->("01234567", 64),  "100", 'to_oct 6');
    is($ns->("01234567", 128), "200", 'to_oct 7');
    is($ns->("01234567", 256), "400", 'to_oct 8');
    is($ns->("01234567", 123), "173", 'to_oct 9');

    # hex
    my $hex = "0123456789abcdef";
    is($ns->($hex, 0),     "0", 'to_hex 1');
    is($ns->($hex, 1),     "1", 'to_hex 2');
    is($ns->($hex, 2),     "2", 'to_hex 3');
    is($ns->($hex, 3),     "3", 'to_hex 4');
    is($ns->($hex, 4),     "4", 'to_hex 5');
    is($ns->($hex, 64),   "40", 'to_hex 6');
    is($ns->($hex, 128),  "80", 'to_hex 7');
    is($ns->($hex, 256), "100", 'to_hex 8');
    is($ns->($hex, 123),  "7b", 'to_hex 9');

    # CAGD system
    my $cagd = "CAGD";
    is($ns->($cagd, 0),       "C", 'to_cagd 1');
    is($ns->($cagd, 1),       "A", 'to_cagd 2');
    is($ns->($cagd, 2),       "G", 'to_cagd 3');
    is($ns->($cagd, 3),       "D", 'to_cagd 4');
    is($ns->($cagd, 4),      "AC", 'to_cagd 5');
    is($ns->($cagd, 64),   "ACCC", 'to_cagd 6');
    is($ns->($cagd, 128),  "GCCC", 'to_cagd 7');
    is($ns->($cagd, 256), "ACCCC", 'to_cagd 8');
    is($ns->($cagd, 123),  "ADGD", 'to_cagd 9');

    my $nums = Sq->rand->int(0,256)->to_array(100);
    is(
        Array::map($nums, Sq->math->to_binary),
        Array::map($nums, sub($x) { $ns->("01", $x) }),
        'to_binary vs to_num_system');

    is(
        Array::map($nums, Sq->math->to_hex),
        Array::map($nums, sub($x) { $ns->("0123456789abcdef", $x) }),
        'to_hex vs to_num_system');
}

# even_spread
{
    my $div = Sq->math->divide_spread;
    is($div->(10,2), [5,5],         'spread 1');
    is($div->(19,4), [4,5,5,5],     'spread 2');
    is($div->(9,3),  [3,3,3],       'spread 3');
    is($div->(10,4), [2,3,2,3],     'spread 4');
    is($div->(11,3), [3,4,4],       'spread 5');
    is($div->(14,3), [4,5,5],       'spread 6');
    is($div->(20,6), [3,3,4,3,3,4], 'spread 7');
    is($div->(16,5), [3,3,3,3,4],   'spread 8');

    check(
        Array::cartesian([10..30], [1..7])->map(sub($tuple) {
            my ($k,$n) = @$tuple;
            [$k,$n,$div->($k,$n)]
        }),
        sub ($array) {
            for my $tuple ( @$array ) {
                my ($k,$n,$array) = @$tuple;
                return 0 if $tuple->[0] != Array::sum($array);
            }
            return 1;
        },
        'spread examples');
}

# even_symmetric
{
    my $div = Sq->math->divide_symmetric;
    is($div->(10,2), [5,5],         'symmetric 1');
    is($div->(19,4), [5,5,5,4],     'symmetric 2');
    is($div->(9,3),  [3,3,3],       'symmetric 3');
    is($div->(10,4), [2,3,3,2],     'symmetric 4');
    is($div->(11,3), [3,4,4],       'symmetric 5');
    is($div->(14,3), [4,5,5],       'symmetric 6');
    is($div->(20,6), [3,3,4,4,3,3], 'symmetric 7');
    is($div->(16,5), [3,3,4,3,3],   'symmetric 8');

    check(
        Array::cartesian([10..30], [1..7])->map(sub($tuple) {
            my ($k,$n) = @$tuple;
            [$k,$n,$div->($k,$n)]
        }),
        sub ($array) {
            for my $tuple ( @$array ) {
                my ($k,$n,$array) = @$tuple;
                return 0 if $tuple->[0] != Array::sum($array);
            }
            return 1;
        },
        'symmetric examples');
}

done_testing;
