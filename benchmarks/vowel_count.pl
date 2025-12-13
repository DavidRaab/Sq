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

my $words = Array::repeat(
    [qw/The big brown fox jumps over the lazy Dog/],
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
});

__END__
Result on my system.

            Rate        cs cs_inline      hash    regexi     regex
cs        78.3/s        --      -91%      -98%      -98%      -98%
cs_inline  852/s      989%        --      -73%      -77%      -77%
hash      3170/s     3948%      272%        --      -14%      -14%
regexi    3691/s     4614%      333%       16%        --       -0%
regex     3692/s     4615%      333%       16%        0%        --
