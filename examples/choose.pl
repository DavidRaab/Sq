#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Getopt::Long::Descriptive;
use Seq;

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['help|h', 'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

my $square  = sub($x) { $x * $x     };
my $is_even = sub($x) { $x % 2 == 0 };

# This defines the Query - but does not compute anything
my $range = Seq->range(1, 10);
my $query = $range->map($square)->filter($is_even);

# you could use to_list to get a list and iterate over it.
for my $x ( $query->to_list ) {
    say $x;
}

# But why do you want to do that? If you need to modify the data
# you should use another function. Maybe fold. The only real
# reason todo this is because you want a side-effect to happen.
# Like printing the values.

# In this case you write
$query->do(sub($x) {
    say $x;
});

# What's the difference?
#
# The do() immediately executes for every computed element.
# But the for-loop first needs to compute all items until it can begin
# printing to the console.

# It doesn't make a difference with 10 elements. But it will make
# a difference if you for example have 100 Million elements.

local $| = 1;

print "Showing 100 Mio dots ...\n";
for my $x ( Seq->range(1, 100_000_000)->to_list ) {
    print ".";
}
print "\n";

# The above code needs about 30 seconds to start printing dots
# and consumes up to 7 GiB of ram. As a list with 100 Mio elements must
# be created

print "Showing 100 Mio dots ...\n";
Seq->range(1, 100_000_000)->do(sub($x) {
    print ".";
});
print "\n";

# The above code start immiadetely to print dots. Memory consumption stays
# at 17 MiB.

