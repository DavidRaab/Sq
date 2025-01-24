#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

# This example shows how to work with Option.
#
# div($x,$y) is a function that returns an optional when $y is zero.
# Instead of throwing an exception
#
# is_positive() is a predicate function to validate a certain value.

# a predicate function
sub is_positive($x) {
    return $x >= 0 ? 1 : 0;
}

# instead of just writing $x/$y we write a function that checks for zero and return None
sub div($x,$y) { return $y == 0 ? None : Some($x / $y) };

# test cases
my @numbers = (
    [1,1,  1,1, 2], # Some(0) | ((1-1) / (1+1)) * 2
    [1,2, -1,1, 2], # None    | because of division by zero
    [0,1,  1,1, 2], # None    | because not positive
    [4,2,  0,1, 2], # Some(4)
);

for my $nums ( @numbers ) {
    my ( $a,$b, $c,$d, $e ) = @$nums;

    # what we want todo:
    # ((is_positive $a - $b) / ($c + $d)) * $e
    my $result =
        Option::bind2(
            Some($a - $b)->validate(\&is_positive),
            Some($c + $d),
            \&div
        )
        ->map(sub($x) { $x * $e });

    # match returns the last expression, but we also can ignore the result when
    # we are just doing side-effects in both cases.
    $result->match(
        None => sub     { printf "No valid result!\n" },
        Some => sub($x) { printf "Result: $x\n"       },
    );
}
