#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Seq qw(fst snd);

# This is definetly not the fastest way to get all possible permutations.
# The point is, that this code still works. computes/prints all permutation
# and starts immidiately without waiting or creating memory problems.

# keys for permutation
my $keys = Seq->wrap(qw/A B C D E F G H I J/);

# only picks permutation so far
my $permutation = sub ($x) {
    my $str = (fst $x) . (snd $x);
    has_duplicates($str) ? undef : $str;
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
$permut->iter(sub ($x) {
    $count++;
    print $x, "\n";
});

printf "Permutation Count: %d\n", $count;

# check if string has duplicate characters
sub has_duplicates($str) {
    my %seen;
    for my $char (split //, $str) {
        return 1 if ++$seen{$char} > 1;
    }
    return 0;
}
