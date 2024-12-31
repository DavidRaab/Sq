#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;

# Read content as single string
my $content = join "", <>;

# Parse Header definition
my $head = "";
if ( $content =~ m/\A (.*?) ^\s*$/xms ) {
    $head = $1;
}
else {
    die "Cannot parse/find header!\n";
}

# Parse lines into columns
my @header =
    grep { @$_ > 0 }
    map  { [m/ (?: \s{3} | \[(.)\] ) (?: \s | $ )/gxms] }
        split /\n/, $head;

# p @header;

# Build initial Stacks
my %stack;
for my $row ( reverse @header ) {
    # printf "ROW: %s\n", (join "|", @$row);
    for (my $idx=0; $idx < @$row; $idx++) {
        if ( defined $row->[$idx] ) {
            push @{$stack{$idx+1}}, $row->[$idx];
        }
    }
}

# p %stack;

# go through move lines
for my $line ( split /\n/, $content ) {
    if ( $line =~ m/\A move \s+ (\d+) \s+ from \s+ (\d+) \s+ to \s+ (\d+) \s* \z/xms ) {
        my $amount = $1;
        my $from   = $2;
        my $target = $3;

        my @tmp;
        for ( 1..$amount ) {
            push @tmp, pop @{ $stack{$from} };
        }
        while ( my $ele = pop @tmp ) {
            push @{ $stack{$target} }, $ele;
        }
    }
}
# p %stack;

# print top of each stack
for my $num ( sort { $a <=> $b } keys %stack ) {
    printf "%s", $stack{$num}[-1];
}
print "\n";

__DATA__
    [D]
[N] [C]
[Z] [M] [P]
 1   2   3

move 1 from 2 to 1
move 3 from 1 to 3
move 2 from 2 to 1
move 1 from 1 to 2