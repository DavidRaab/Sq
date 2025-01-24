#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

my $square  = sub($x) { $x * $x     };
my $is_even = sub($x) { $x % 2 == 0 };

# This defines the Query - but does not compute anything
my $range = Seq->range(1, 10);
my $query = $range->map($square)->keep($is_even);

# you could use expand to get a list and iterate over it.
for my $x ( $query->expand ) {
    say $x;
}

# But why do you want to do that? If you need to modify the data
# you should use another function. Maybe fold. The only real
# reason todo this is because you want a side-effect to happen.
# Like printing the values.

# In this case you write
$query->iter(sub($x) {
    say $x;
});

# What's the difference?
#
# The iter() immediately executes for every computed element.
# But the for-loop first needs to compute all items until it can begin
# printing to the console.

# It doesn't make a difference with 10 elements. But it will make
# a difference if you for example have 100 Million elements.

local $| = 1;

# This can crash your computer

=pod

print "Showing 100 Mio dots ...\n";
for my $x ( Seq->range(1, 100_000_000)->expand ) {
    print ".";
}
print "\n";

=cut

# The above code needs about 30 seconds to start printing dots
# and consumes up to 7 GiB of ram. As a list with 100 Mio elements must
# be created

print "Showing 100 Mio dots ...\n";
Seq->range(1, 100_000_000)->iter(sub($x) {
    print ".";
});
print "\n";

# The above code start immiadetely to print dots. Memory consumption stays
# at 17 MiB.

