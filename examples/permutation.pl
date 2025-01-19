#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
#use Sq::Sig;

# permute() is now part of Array/Seq. Use this one as it is much faster.
# See "examples/permute.pl"
#
# Runtime:
# examples/permutation.pl -> ~300 secs
# examples/permute.pl     -> ~17 secs
#
# This stays as an example as it still shows the laziness of a Sequence.
#
# This is definetly not the fastest way to get all possible permutations.
# The point is, that this code still works. computes/prints all permutation
# and starts immediately without waiting or creating memory problems.

# keys for permutation
my $keys = seq { qw/A B C D E F G H I J/ };

# only picks permutation so far
my $permutation = sub ($x) {
    my $str = (fst $x) . (snd $x);
    has_duplicates($str) ? None : Some $str;
};

# defines all permutations
my $permut =
    $keys
    ->cartesian($keys)->choose($permutation)
    ->cartesian($keys)->choose($permutation)
    ->cartesian($keys)->choose($permutation)
    ->cartesian($keys)->choose($permutation)
    ->cartesian($keys)->choose($permutation)
    ->cartesian($keys)->choose($permutation)
    ->cartesian($keys)->choose($permutation)
    ->cartesian($keys)->choose($permutation)
    ->cartesian($keys)->choose($permutation);

# Start printing permutations
my $count = 0;
Sq->bench->it(sub {
    $permut->iter(sub ($x) {
        $count++;
        print $x, "\n";
    });
});

printf "Permutation Should be: %d\n", Sq->math->fac(10);
printf "Permutation Count: %d\n", $count;

# check if string has duplicate characters
sub has_duplicates($str) {
    my %seen;
    for my $char (split //, $str) {
        return 1 if ++$seen{$char} > 1;
    }
    return 0;
}
