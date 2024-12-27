#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Benchmark qw(cmpthese);

# In Sq i often need to check if a ref is either Array or Array. Same goes
# with Hash and Hash. So here i try to determine which version is fastest.
# The @data contains many more keys as just the needed one because it resembles
# real data more. I am not just getting Array all the time in all checks.
# Then i wouldn't need the check to begin with.
#
# In my benchmark and on my system so far i see that the "lc" version is
# the fastest, but also the and2 version with checking the length prior
# can be faster depending on @data

my @data = qw(Array Option Hash Array Result ARRAY HASH Seq);
cmpthese(-1, {
    and => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( $data eq 'Array' || $data eq 'ARRAY' ) {
                    $count++;
                }
            }
        }
    },
    and2 => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( length($data) == 5 && ($data eq 'Array' || $data eq 'ARRAY') ) {
                    $count++;
                }
            }
        }
    },
    regex_or => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( $data =~ m/\AArray|ARRAY\z/ ) {
                    $count++;
                }
            }
        }
    },
    regex_or2 => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( $data =~ m/\AA(?:rray|RRAY)\z/ ) {
                    $count++;
                }
            }
        }
    },
    regex_i => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( $data =~ m/\AArray\z/i ) {
                    $count++;
                }
            }
        }
    },
    regex_char => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( $data =~ m/\AA[rR][rR][aA][yY]\z/i ) {
                    $count++;
                }
            }
        }
    },
    fc => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( fc $data eq fc "Array" ) {
                    $count++;
                }
            }
        }
    },
    lc => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( lc $data eq "array" ) {
                    $count++;
                }
            }
        }
    },
    uc => sub {
        my $count = 0;
        for ( 1 .. 1_000 ) {
            for my $data ( @data ) {
                if ( uc $data eq "ARRAY" ) {
                    $count++;
                }
            }
        }
    }
});