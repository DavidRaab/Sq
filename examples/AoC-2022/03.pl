#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::Util qw(sum0 uniqstr);
use List::MoreUtils qw(zip natatime);

# https://adventofcode.com/2022/day/3

# Build Priority mapping hash
my $p        = 1;
my %priority = map { $_ => $p++ } 'a' .. 'z', 'A' .. 'Z';

# Parse everything into @bags
my @bags;
my @splitted;
while ( my $line = <> ) {
    chomp $line;
    my @chars  = split //, $line;
    push @bags, \@chars;

    my $middle = @chars / 2;
    my @left   = @chars[0..$middle-1];
    my @right  = @chars[$middle..$#chars];
    push @splitted, [ \@left, \@right ];
}

# Getting sum of priority of intersections
my $sum = sum0 map { $priority{$_} } map { intersect($_->[0], $_->[1]) } @splitted;
printf "Sum: %d\n", $sum;

# Part2
my $sum2 = 0;
my $it = natatime 3, @bags;
while (my @vals = $it->()) {
    my @inter = intersect([intersect($vals[0], $vals[1])], $vals[2]);
    $sum2 += sum0 map { $priority{$_} } @inter;
}
printf "Sum2: %d\n", $sum2;

# return intersections of two arrays
sub intersect ($left, $right) {
    my %containing = map { $_ => 1 } @$left;

    my @dups;
    for my $entry ( @$right ) {
        if ( exists $containing{$entry} ) {
            push @dups, $entry;
        }
    }

    return uniqstr @dups;
}

__DATA__
vJrwpWtwJgWrhcsFMMfFFhFp
jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
PmmdzqPrVvPwwTWBwg
wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
ttgJtRGJQctTZtZT
CrZsJsPPZsGzwwsLwLmpwMDw
