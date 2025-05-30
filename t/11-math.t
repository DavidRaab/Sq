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

done_testing;
