#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Getopt::Long;

my $rounds = 20;
my $test   = 0;
GetOptions(
    't|test'     => \$test,
    'r|rounds=i' => \$rounds,
) or die "Error parsing command line arguments\n";

sub add ($x) { return sub ($old) { $old + $x } }
sub mul ($x) { return sub ($old) { $old * $x } }

my @test = (
    # 0
    {
        items     => [79, 98],
        inspect   => mul(19),
        divisible => [23,2,3],
    },
    # 1
    {
        items     => [54,65,75,74],
        inspect   => add(6),
        divisible => [19,2,0],
    },
    # 2
    {
        items     => [79,60,97],
        inspect   => sub ($old) { $old * $old },
        divisible => [13,1,3],
    },
    # 3
    {
        items     => [74],
        inspect   => add(3),
        divisible => [17,0,1],
    },
);

my @input = (
    # 0
    {
        items     => [89, 95, 92, 64, 87, 68],
        inspect   => mul(11),
        divisible => [2,7,4],
    },
    # 1
    {
        items     => [87,67],
        inspect   => add(1),
        divisible => [13,3,6],
    },
    # 2
    {
        items     => [95, 79, 92, 82, 60],
        inspect   => add(6),
        divisible => [3,1,6],
    },
    # 3
    {
        items     => [67, 97, 56],
        inspect   => sub ($old) { $old * $old },
        divisible => [17,7,0],
    },
    # 4
    {
        items     => [80, 68, 87, 94, 61, 59, 50, 68],
        inspect   => mul(7),
        divisible => [19,5,2],
    },
    # 5
    {
        items     => [73, 51, 76, 59],
        inspect   => add(8),
        divisible => [7,2,1],
    },
    # 6
    {
        items     => [92],
        inspect   => add(5),
        divisible => [11,3,0],
    },
    #7
    {
        items     => [99, 76, 78, 76, 79, 90, 89],
        inspect   => add(7),
        divisible => [5,4,5],
    },
);

my @monkeys = $test ? @test : @input;

$| = 1;
for my $round ( 1 .. $rounds ) {
    for my $monkey ( @monkeys ) {
        while ( my $item = shift $monkey->{items}->@* ) {
            $monkey->{inspected}++;

            # extract diviible parameters
            my ($div, $true, $false) = $monkey->{divisible}->@*;

            # Part 1
            my $inspect     = $monkey->{inspect}($item);
            my $new         = int ($inspect / 3);
            my $next_monkey = $new % $div == 0 ? $true : $false;
            push $monkeys[$next_monkey]{items}->@*, $new;

            # Part 2
            # my $inspect = $monkey->{inspect}($item);
            # if ( $inspect % $div == 0 ) {
            #     push $monkeys[$true]{items}->@*, $div;
            # }
            # else {
            #     push $monkeys[$false]{items}->@*, $inspect;
            # }

            # printf "Inspect %d New %d Next %d\n", $inspect, $new, $next_monkey;
        }
    }
    # print ".";
    # printf "After Round %d\n", $round;
    # show_items(@monkeys);
    # print "\n";
}

printf "After %d Rounds\n\n", $rounds;
print "Items:\n";
show_items(@monkeys);
print "\nInspected:\n";
show_inspected(@monkeys);

my ($fst, $snd) = sort { $b <=> $a } map { $_->{inspected} } @monkeys;
printf "\nMonkey Business: %d * %d = %d\n", $fst, $snd, $fst * $snd;

sub show_items (@monkeys) {
    my $idx = 0;
    for my $monkey ( @monkeys ) {
        printf "Monkey %d: %s\n", $idx++, join(", ", $monkey->{items}->@*);
    }
}

sub show_inspected (@monkeys) {
    my $idx = 0;
    for my $monkey ( @monkeys ) {
        printf "Monkey %d: %s\n", $idx++, $monkey->{inspected};
    }
}