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
my $win      = "WIN";
my $draw     = "DRAW";
my $lose     = "LOSE";

my $input_mapping = {
    A => $rock,
    B => $paper,
    C => $scissors,
    X => $lose,
    Y => $draw,
    Z => $win,
};

my $tool_points = {
    $rock     => 1,
    $paper    => 2,
    $scissors => 3
};

my $choose = {
    $rock => {
        $win  => $paper,
        $draw => $rock,
        $lose => $scissors,
    },
    $paper => {
        $win  => $scissors,
        $draw => $paper,
        $lose => $rock,
    },
    $scissors => {
        $win  => $rock,
        $draw => $scissors,
        $lose => $paper,
    },
};

my $winning_points = {
    $rock => {
        $rock     => 3,
        $paper    => 6,
        $scissors => 0,
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

# Build Data-Structure
my @data = map {
    m/\A ([ABC]) \s+ ([XYZ]) \Z/xms && [ $input_mapping->{$1}, $input_mapping->{$2} ]
} <>;

# Calculate the points
my $plan_points = 0;
for my $plan ( @data ) {
    my ( $other, $target ) = @$plan;
    my $tool = $choose->{$other}{$target};
    $plan_points += $tool_points->{$tool} + $winning_points->{$other}{$tool};
}

# Print result
printf "Total Points: %d\n", $plan_points;

__DATA__
A Y
B X
C Z