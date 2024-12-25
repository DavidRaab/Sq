#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;
use Time::HiRes qw(time);

my $first  =
    Seq
    ->range(1,1_000_000_000)
    ->do(sub($num){ print "$num\n" if $num % 100_000 == 0 });
my $second =
    Seq->range(1,1_000_000_000);

my $start = time();

print "Are those sequences lazy?\n";
if ( equal($first,$second) ) {
    print "Yep!\n";
}
else {
    print "No!\n";
}

my $stop = time();
printf "Time took: %f seconds\n", ($stop - $start);
