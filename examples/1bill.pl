#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;
use Time::HiRes qw(time);

my $first  =
    Seq
    ->range(0,1_000_000_000)
    ->do_every(100_000, sub($num,$idx){ print "$num\n" });

my $second =
    Seq->range(0,1_000_000_000);

my $start = time();

print "Are those sequences lazy?\n";
if ( equal($first,$second) ) {
    print "Yep!\n";
}
else {
    print "Yep!\n";
}

my $stop = time();
printf "Time took: %f seconds\n", ($stop - $start);
