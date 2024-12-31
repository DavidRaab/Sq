#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::MoreUtils qw(firstidx);

# Read input
my $content = join "", <>;
my @input;
while ( $content =~ m/^ (\N+) \n (\N+) (?: \n\n | $) /xmsg ) {
    push @input, [eval $1, eval $2];
}

# Part 1
my $sum_idx = 0;
my $idx = 1;
for my $tuple ( @input ) {
    my ($left, $right) = @$tuple;
    my $res = compare($left, $right);
    if ( $res == -1 ) {
        $sum_idx += $idx;
    }
    $idx++;
}

printf "Sum of Right Orders: %d\n", $sum_idx;

# Part 2
my @sorted = sort { compare($a,$b) } map { @$_ } @input, [[[2]], [[6]]];
my $i1     = (firstidx { is_equal($_, [[2]]) } @sorted) + 1;
my $i2     = (firstidx { is_equal($_, [[6]]) } @sorted) + 1;

printf "Multiplication %d * %d = %d\n", $i1, $i2, $i1 * $i2;


# head/tail for arrays that returns copy instead of mutating array
sub head($list) { $list->[0] }
sub tail($list) { [$list->@[1 .. $list->$#*]] }

# left is:
# -1 = smaller, 0 = equal, 1 = greater
sub compare ($left, $right) {
    my $l = head $left;
    my $r = head $right;

    return  0 if !defined $l && !defined $r;
    return -1 if !defined $l &&  defined $r;
    return  1 if  defined $l && !defined $r;

    # if both arrays
    if ( ref $l  &&  ref $r ) {
        my $res = compare($l, $r);
        return $res if $res;
    }

    # if both numbers
    if ( !ref $l  &&  !ref $r ) {
        return -1 if $l < $r;
        return  1 if $l > $r;
        goto NEXT;
    }

    # number; array
    if ( !ref $l  &&  ref $r ) {
        my $res = compare([$l], $r);
        return $res if $res;
    }

    # array; number
    if ( ref $l  &&  !ref $r ) {
        my $res = compare($l, [$r]);
        return $res if $res;
    }

    NEXT:
    @_ = (tail($left), tail($right));
    goto &compare;
}

# comparison function for arrays of any depth. But compares numbers only
sub is_equal($left, $right) {
    return 0 if !defined $left || !defined $right;
    return 0 if ref $left  ne 'ARRAY';
    return 0 if ref $right ne 'ARRAY';
    return 1 if @$left == 0 && @$right == 0;
    return 0 if @$left == 0 || @$right == 0;

    my $h1 = head $left;
    my $h2 = head $right;

    if ( ref $h1 && ref $h2 ) {
        is_equal($h1,$h2) ? goto NEXT : return 0;
    }
    elsif ( ref $h1 || ref $h2 ) {
        return 0;
    }
    else {
        $h1 == $h2 ? goto NEXT : return 0;
    }

    return 1;

    NEXT:
    @_ = ((tail $left), (tail $right));
    goto &is_equal;
}