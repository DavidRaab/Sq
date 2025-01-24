#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

# 1 billion
my $big = Seq->range(1,1_000_000_000);

# two different branches of 1 billion
my $double  = $big->map(sub($x) { $x * 2  });
my $squared = $big->map(sub($x) { $x * $x });

# zip those together
my $zipped = Seq::zip($double, $squared);

# only take(10) elements from it.
my $only10 = $zipped->take(10);

# compare
is(
    $only10,
    seq {
        [  2,   1 ],
        [  4,   4 ],
        [  6,   9 ],
        [  8,  16 ],
        [ 10,  25 ],
        [ 12,  36 ],
        [ 14,  49 ],
        [ 16,  64 ],
        [ 18,  81 ],
        [ 20, 100 ]
    },
    'build something small 1');

# or functional-style
# definining Seq->range twice doesn't really matter.
is(
    Seq::zip(
        Seq->range(1,1_000_000_000)->map(sub($x) { $x * 2  }),
        Seq->range(1,1_000_000_000)->map(sub($x) { $x * $x }),
    )->take(10),
    seq {
        [  2,   1 ],
        [  4,   4 ],
        [  6,   9 ],
        [  8,  16 ],
        [ 10,  25 ],
        [ 12,  36 ],
        [ 14,  49 ],
        [ 16,  64 ],
        [ 18,  81 ],
        [ 20, 100 ]
    },
    'build something small 2');

done_testing;
