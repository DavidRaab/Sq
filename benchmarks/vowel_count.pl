#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;

# Typical C# solution i found in internet, transfered to Perl.
#
# Uses a pre-defined functions for array scanning. Definetly the slowest in Sq.
# Because of Array Scanning, function call overhead, and it uses a generic
# equal() that can check any types.
sub vowel_cs($text) {
    state @vowels = (qw/a e i o u A E I O U/);
    my $count = 0;
    for my $char ( split //, $text ) {
        if ( Array::contains(\@vowels, $char) ) {
            $count++;
        }
    }
    return $count;
}

# Maybe how a C devs writes it without a function like Array::contains
# still makes it faster as it has no function call in the loop. And we
# can directly use string "eq" for checking.
sub vowel_cs_inline($text) {
    state @vowels = (qw/a e i o u A E I O U/);
    my $count  = 0;
    for my $char ( split //, $text ) {
        for my $vowel ( @vowels ) {
            if ( $char eq $vowel ) {
                $count++;
            }
        }
    }
    return $count;
}

# Typical Perl solution is to build a hash instead of array scanning.
# This comes Array::contains very close! And it also is. A hash is a
# data-structure that allows key->value mapping in a more efficent way
# than scanning an Array.
sub vowel_hash($text) {
    state %vowel = map { $_ => 1 } (qw/a e i o u A E I O U/);
    my $count    = 0;
    for my $char ( split //, $text ) {
        if ( $vowel{$char} ) {
            $count++;
        }
    }
    return $count;
}

# Even more perlish. Using a regex. We just extract all vowels into a
# whole new array. Then count how many matches we had.
sub vowel_regex($text) {
    my @matches = $text =~ m/[aeiouAEIOU]/g;
    return scalar @matches;
}

# Same, but using regex ignore case function
sub vowel_regexi($text) {
    my @matches = $text =~ m/[aeiou]/gi;
    return scalar @matches;
}

# this uses tr//, it is specialiased to just replace characters. it
# returns how many replacements are made. This avoid building an array
# of matches. With no replacement it just counts the specified characters.
sub vowel_tr($text) {
    return $text =~ tr/aeiouAEIOU//;
}

my $words = Array::repeat(
    [qw/The big brOwn fox jumps ovEr the lazy Dog/],
    100);

Sq->bench->compare(-1, {
    cs => sub {
        my $count = 0;
        for my $word ( @$words ) {
            $count += vowel_cs($word);
        }
        die "\$count not correct" if $count != 1000;
    },
    cs_inline => sub {
        my $count = 0;
        for my $word ( @$words ) {
            $count += vowel_cs_inline($word);
        }
        die "\$count not correct" if $count != 1000;
    },
    hash => sub {
        my $count = 0;
        for my $word ( @$words ) {
            $count += vowel_hash($word);
        }
        die "\$count not correct" if $count != 1000;
    },
    regex => sub {
        my $count = 0;
        for my $word ( @$words ) {
            $count += vowel_regex($word);
        }
        die "\$count not correct" if $count != 1000;
    },
    regexi => sub {
        my $count = 0;
        for my $word ( @$words ) {
            $count += vowel_regexi($word);
        }
        die "\$count not correct" if $count != 1000;
    },
    tr => sub {
        my $count = 0;
        for my $word ( @$words ) {
            $count += vowel_tr($word);
        }
        die "\$count not correct" if $count != 1000;
    },
    # this just shows the overhead of calling 1 function in a loop
    tr_inline => sub {
        my $count = 0;
        for my $word ( @$words ) {
            $count += $word =~ tr/aeiouAEIOU//;
        }
        die "\$count not correct" if $count != 1000;
    },
});

__END__
Result on my system.

             Rate      cs cs_inline     hash  regexi    regex       tr tr_inline
cs         74.5/s      --      -91%     -98%    -98%     -98%     -99%     -100%
cs_inline   853/s   1045%        --     -73%    -77%     -77%     -92%      -97%
hash       3110/s   4074%      264%       --    -16%     -17%     -72%      -90%
regexi     3692/s   4855%      333%      19%      --      -2%     -67%      -89%
regex      3759/s   4945%      341%      21%      2%       --     -66%      -88%
tr        11061/s  14745%     1196%     256%    200%     194%       --      -66%
tr_inline 32119/s  43008%     3664%     933%    770%     754%     190%        --
