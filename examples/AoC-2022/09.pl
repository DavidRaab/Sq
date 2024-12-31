#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::Util qw(sum0 any);
use Getopt::Long;

my ($width, $height) = (16, 16);
my $length    = 2;
my $visualize = 0;
GetOptions(
    'v|visualize' => \$visualize,
    'w|width=i'   => \$width,
    'h|height=i'  => \$height,
    'l|length=i'  => \$length,
) or die "Error in command line arguments\n";

# Creates a vector
sub vector ($x,$y) {
    return { X => $x, Y => $y };
}

# Default vectors
my $up    = vector(0,1);
my $right = vector(1,0);
my $down  = vector(0,-1);
my $left  = vector(-1,0);

# Initial state - begin in center - useful if visualization is active
my @snake = map { vector($width/2, $height/2) } 1 .. $length;

print visualize($width,$height,@snake), "\n" if $visualize;

# Position visited
my %visited;

for my $line ( <> ) {
    if ( $line =~ m/\A ([RULD]) \s+ (\d+) \Z/xms ) {
        my $dir    = $1;
        my $amount = $2;

        state $movement = {
            'R' => $right,
            'U' => $up,
            'L' => $left,
            'D' => $down,
        };

        for my $x ( 1 .. $amount ) {
            # Apply movement from line to head
            $snake[0] = add($snake[0], $movement->{$dir});

            # Update all Snake Parts
            for my $idx ( 1 .. $#snake ) {
                my $head = $snake[$idx-1];
                my $tail = $snake[$idx];

                # When not adjacent then also move tail
                if ( not is_adjacent($head,$tail) ) {
                    $snake[$idx] = add($tail, direction($tail, $head));
                }
            }

            # Save which positions the tail visited
            $visited{join ",", $snake[-1]->{X}, $snake[-1]->{Y}} = 1;
        }

        # Visualize
        if ( $visualize ) {
            printf "%s => %d\n", $dir, $amount;
            print visualize($width,$height,@snake), "\n";
        }
    }
}

my $sum_visited = scalar keys %visited;
printf "Visited: %d\n", $sum_visited;

sub show ($vector) {
    return sprintf "(%d,%d)", $vector->{X}, $vector->{Y};
}

# check if two vectors are adjacent to each other
sub is_adjacent ($head, $tail) {
    my $diff_x = $head->{X} - $tail->{X};
    my $diff_y = $head->{Y} - $tail->{Y};
    if ( any { $diff_x == $_ } -1, 0, 1 ) {
        if ( any { $diff_y == $_ } -1, 0, 1 ) {
            return 1;
        }
    }
    return 0;
}

# Adds two vectors
sub add ($v1, $v2) {
    return {
        X => $v1->{X} + $v2->{X},
        Y => $v1->{Y} + $v2->{Y},
    };
}

sub equal ($v1,$v2) {
    return $v1->{X} == $v2->{X} && $v1->{Y} == $v2->{Y};
}

# Returns a vector that moves $from in the direction to $to
sub direction ($from, $to) {
    return vector(0,0) if equal($from,$to);

    # If in the same column
    my $hori = vector(0,0);
    $hori = $up   if $from->{Y} < $to->{Y};
    $hori = $down if $from->{Y} > $to->{Y};

    # if in the same row
    my $vertical = vector(0,0);
    $vertical = $right if $from->{X} < $to->{X};
    $vertical = $left  if $from->{X} > $to->{X};

    return add($hori,$vertical);
}

sub visualize ($width, $height, @snake) {
    my @field = map {[(".") x $width]} 1 .. $height;

    my ($head, @parts) = @snake;
    $field[$head->{Y}][$head->{X}] = "H";

    my $num = 1;
    for my $tail ( @parts ) {
        if ( $field[$tail->{Y}][$tail->{X}] eq '.' ) {
            $field[$tail->{Y}][$tail->{X}] = $num;
        }
        $num++;
    }

    return reverse map { join("", @$_) . "\n" } @field;
}