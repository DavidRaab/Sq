#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';

my $reset = "\e[m";

for my $x ( 1 .. 255 ) {
    print $reset;
    printf "%03d -> \e[38;5;%dmhello    ", $x, $x;
    print "\n" if $x % 6 == 0;
}
print "\n";