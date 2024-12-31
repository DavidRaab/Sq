#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::Util qw(sum0 pairs);

# Run with: ./01.pl 01.input
# https://adventofcode.com/2022/day/1

# Read whole file as a single string
my $content = join "", <>;

# Regex to parse content block-wise
my $block = qr/
    (                     # $1
        (?:
            ^             # Start of line ...
            \d+           # containing digits ...
            (?: \n | $ )  # upto end of line.
        )+                # one or many of them
    )
/xm;

# Parse content into a data-structure
my $idx = 1;
my %elf;
while ( $content =~ m/$block/g ) {
    my @nums = $1 =~ m/^ (\d+) $/xmg;
    $elf{$idx++} = \@nums;
}

# Data-Structur looks like
# {
#    1 => [1000,2000,3000],
#    2 => [4000],
#    3 => [5000,6000],
#    4 => [7000,8000,9000],
#    5 => [10000],
# }

# Get Elf with most calories
my ($elf, $calories) = max_by(\%elf, sub ($value) { sum0 @$value });

# Print the Result
printf "Elf %d has most calories with %d calories\n", $elf, $calories;


# Part 2:
# Turn elfs into a sorted array by sumed calories, descending
my @elfs =
    sort { $b->[1] <=> $a->[1]          }
    map  { [$_->[0], sum0 $_->[1]->@* ] }
        pairs %elf;

# Sum calories of first three elfs
my $sum_first_three = sum0(map { $_->[1] } @elfs[0..2]);
printf "Sum First Three: %d\n", $sum_first_three;



# A generic hash utilty function that returns the key/value of the
# highest value. value is calculated by the function $f.
# numeric ">" is used for determining highest value.
sub max_by ($hash, $f) {
    my ($max_key, $max_value) = ("", 0);
    while ( my ($key, $value) = each %$hash ) {
        my $current = $f->($value);
        if ( $current > $max_value ) {
            $max_key   = $key;
            $max_value = $current;
        }
    }
    return ($max_key, $max_value);
}
