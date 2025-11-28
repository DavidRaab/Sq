#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;
use Devel::Size qw(total_size);

sub by_regex($str) {
    my $count = 0;
    for my $char ( split //, $str ) {
        $count++;
    }
    return $count;
}

sub by_substr($str) {
    my $count  = 0;
    my $offset = 0;
    my $length = length($str);
    my $char;
    while ( $offset < $length ) {
        $char = substr($str, $offset++, 1);
        $count++;
    }
    return $count;
}

# this is not directly compareable. But i am interested when a
# string is saved as an char array from the beginning if it is
# faster compared to using a string. This will probably take more
# memory.
sub by_array($char_array) {
    my $count = 0;
    for my $char ( @$char_array ) {
        $count++;
    }
    return $count;
}

# another approach is to save everything as array of strings. Every
# line is a string.
sub by_aos($str_array) {
    my $count = 0;
    for my $line ( @$str_array ) {
        for my $char ( split //, $line ) {
            $count++;
        }
    }
    return $count;
}

# Why 211 * 52?
# this is the size of a fullscreen terminal window on my display. Type
# the following into terminal to get sizes:
#   tput cols
#   tput lines
my $width  = 211;
my $height = 52;
my $amount = $width * $height;

my $str       = Sq->rand->str($amount)->first("");
my @str       = split //, $str;
my $str_array = Str->chunk($str, $width);

is($str, $str_array->join, 'chunk works correctly');
is(by_regex ($str),    $amount, 'by_regex');
is(by_substr($str),    $amount, 'by_substr');
is(by_array(\@str),    $amount, 'by_array');
is(by_aos($str_array), $amount, 'by_aos');
done_testing;

printf "Size: \$str:       %d bytes\n", total_size($str);
printf "Size: \@str:       %d bytes\n", total_size(\@str);
printf "Size: \$str_array: %d bytes\n", total_size($str_array);
printf "Factor \@str:\$str: %f\n", (total_size(\@str) / total_size($str));

Sq->bench->compare(-1, {
    regex  => sub { by_regex ($str)    },
    substr => sub { by_substr($str)    },
    array  => sub { by_array(\@str)    },
    AoS    => sub { by_aos($str_array) },
});
