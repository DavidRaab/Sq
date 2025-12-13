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
# of matches
sub vowel_tr($text) {
    my $count = $text =~ tr/aeiouAEIOU/aeiouAEIOU/;
    return $count;
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
});

__END__
Result on my system.

            Rate        cs cs_inline      hash     regex    regexi        tr
cs        75.5/s        --      -91%      -97%      -98%      -98%      -99%
cs_inline  852/s     1030%        --      -71%      -77%      -77%      -91%
hash      2955/s     3816%      247%        --      -20%      -21%      -69%
regex     3691/s     4792%      333%       25%        --       -1%      -61%
regexi    3725/s     4837%      337%       26%        1%        --      -60%
tr        9394/s    12351%     1002%      218%      155%      152%        --
