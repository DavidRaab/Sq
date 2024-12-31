#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;

# https://adventofcode.com/2022/day/2

# Did you know that functions are just mappings from input to output?

# Thus a hash also can be seens as a function. INPUT => OUTPUT is the same as
# KEY => VALUE. But only makes sense to write this if the amount of different
# inputs are limited.

my $rock     = "ROCK";
my $paper    = "PAPER";
my $scissors = "SCISSORS";

my $input_mapping = {
    A => $rock,
    B => $paper,
    C => $scissors,
    X => $rock,
    Y => $paper,
    Z => $scissors,
};

my $tool_points = {
    $rock     => 1,
    $paper    => 2,
    $scissors => 3
};

my $winning_points = {
    $rock => {
        $rock     => 3, # DRAW
        $paper    => 6, # WIN
        $scissors => 0, # LOSS
    },
    $paper => {
        $rock     => 0,
        $paper    => 3,
        $scissors => 6,
    },
    $scissors => {
        $rock     => 6,
        $paper    => 0,
        $scissors => 3,
    },
};

# First i parse the input to a data-structure like this
# [
#   ["ROCK",     "PAPER"],
#   ["PAPER",    "ROCK"],
#   ["SCISSORS", "SCISSORS"],
# ]

# Build Data-Structure
my @data = map {
    m/\A ([ABC]) \s+ ([XYZ]) \Z/xms && [ $input_mapping->{$1}, $input_mapping->{$2} ]
} <>;

# Calculate the points
my $plan_points = 0;
for my $plan ( @data ) {
    my ( $other, $me ) = @$plan;
    $plan_points += $tool_points->{$me} + $winning_points->{$other}{$me};
}

# Print result
printf "Total Points: %d\n", $plan_points;
