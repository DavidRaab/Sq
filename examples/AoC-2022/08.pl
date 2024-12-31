#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::Util qw(max sum0 all);

# read file as Array of Array
my @forest = map {[grep { not m/\A\s+\z/ } split //]} <>;
my $width  = max map { scalar @$_ } @forest;
my $height = @forest;

print_aoa(\@forest);

my @seen;
for my $y ( 0 .. $height-1 ) {
    my @result;
    for my $x ( 0 .. $width-1 ) {
        push @result, can_be_seen($x,$y,\@forest);
    }
    push @seen, \@result;
}

print_aoa(\@seen);

# Add Visible trees together
my $visible = sum0 map {map { s/\A([TLBR])\z/1/gr } @$_} @seen;
printf "Visible: %d\n", $visible;

# Part 2 - Compute Score
my @scores;
for my $y ( 0 .. $height-1 ) {
    for my $x ( 0 .. $width-1 ) {
        push @scores, score($x,$y,\@forest);
    }
}
printf "Max Score: %d\n", max @scores;



sub range ($x,$y) {
    return $x <= $y ? $x .. $y : reverse $y .. $x;
}

sub top_trees ($x, $y, $forest) {
    return $y == 0         ? () : map { $forest->[$_][$x] } range($y-1, 0);
}

sub bottom_trees ($x, $y, $forest) {
    return $y == $height-1 ? () : map { $forest->[$_][$x] } range($y+1,$height-1);
}

sub left_trees ($x, $y, $forest) {
    return $x == 0         ? () : map { $forest->[$y][$_] } range($x-1,0);
}

sub right_trees ($x, $y, $forest) {
    return $x == $width-1  ? () : map { $forest->[$y][$_] } range($x+1,$width-1);
}


sub can_be_seen ($x, $y, $forest) {
    my $current = $forest->[$y][$x];
    return "L" if all { $current > $_ } left_trees  ($x,$y,$forest);
    return "R" if all { $current > $_ } right_trees ($x,$y,$forest);
    return "T" if all { $current > $_ } top_trees   ($x,$y,$forest);
    return "B" if all { $current > $_ } bottom_trees($x,$y,$forest);
    return 0;
}

# Consumes every element of a list until (including) the predicate returns true
sub untilf ($f, @rest) {
    my @result;
    for my $value ( @rest ) {
        if    ( not $f->($value) ) { push @result, $value;       }
        elsif ( $f->($value)     ) { push @result, $value; last; }
        else                       { last; }
    }
    return @result;
}

sub score ($x, $y, $forest) {
    my $current = $forest->[$y][$x];

    my @left   = untilf(sub ($x) { $x >= $current }, left_trees($x,$y,$forest));
    my @right  = untilf(sub ($x) { $x >= $current }, right_trees($x,$y,$forest));
    my @top    = untilf(sub ($x) { $x >= $current }, top_trees($x,$y,$forest));
    my @bottom = untilf(sub ($x) { $x >= $current }, bottom_trees($x,$y,$forest));

    return @left * @right * @top * @bottom;
}

sub print_aoa ($aoa) {
    for my $row ( @$aoa ) {
        for my $col ( @$row ) {
            printf "%s", $col;
        }
        print "\n";
    }
    print "\n";
}