#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;

# Generates random permutations in an infinity stream. Because it is random
# it doesn't know when all possible combinations are tried. But you can limit
# the amount of tries with for example ->take(100_000)

sub permute_random($array) {
    my $freeze = Array::copy($array);
    Seq->from_sub(sub {
        my $new = Array::copy($freeze);
        return sub {
            $new = Array::shuffle($new);
            return $new;
        }
    });
}

# random permutation - runs forever - don't know when it finishs
my $permut = permute_random([qw/A B C D E F G H I J/]); #->take(1_000_000);

# Start printing permutations
$permut->iter(sub ($array) {
    print $array->join(""), "\n";
});
