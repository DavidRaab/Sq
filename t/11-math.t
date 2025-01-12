#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

{
    my $primes =
        Seq
        ->up(2)
        ->keep(sub($x) { Sq->math->is_prime($x) })
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
        ->keep(Sq->math->is_prime)
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
        ->keep(Sq::Math::is_prime)
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

done_testing;
