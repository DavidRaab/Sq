#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::MoreUtils qw(duplicates);

# https://adventofcode.com/2022/day/4

my $contains = 0;
my $overlaps = 0;
while ( my $line = <> ) {
    if ( $line =~ m/\A (\d+) - (\d+) , (\d+) - (\d+) \Z/x ) {
        if ( $1 >= $3 && $2 <= $4 or $3 >= $1 && $4 <= $2 ) {
            $contains++;
        }
        if ( duplicates ((int $1)..(int $2), (int $3)..(int $4)) ) {
            $overlaps++;
        }
    }
}

printf "Contained: %d\n", $contains;
printf "Overlaps:  %d\n", $overlaps;

__DATA__
2-4,6-8
2-3,4-5
5-7,7-9
2-8,3-7
6-6,4-6
2-6,4-8
11-20,15-18
10-20,1-40
