#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::MoreUtils qw(duplicates);

open my $fh, '<', '06.input' or die "Cannot open file '06.input': $!\n";

my $length = 14;
my @buffer;

my $processed = 0;
while ( defined (my $char = getc $fh) ) {
    $processed++;

    push @buffer, $char;
    if ( @buffer > $length ) {
        shift @buffer;
    }
    if ( @buffer == $length ) {
        if ( duplicates(@buffer) == 0 ) {
            printf "%d\n", $processed;
            last;
        }
    }
}

close $fh;

__DATA__
mjqjpqmgbljsphdztnvjfqwrcgsmlb
