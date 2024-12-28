#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Getopt::Long::Descriptive;
use Sq;
use Sq::Sig;

# https://adventofcode.com/2023/day/1

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['file|f=s', 'file to work with',  {required     => 1}],
    ['help|h',   'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

my $first_and_last = sub($array) {
    [ $array->first->or(0), $array->last->or(0) ]
};

my $sum =
    Sq->fs->open_text($opt->file)
    # removes newline
    ->map(sub($str)    { chomp $str; $str                    })
    ->doi(sub($str,$i) { printf "%4d %s", $i, $str           })
    ->map(sub($line)   { digitize($line)                     })
    ->do( sub($str)    { printf " %s", $str                  })
    # split every string into an array. creates seq of array
    ->split(qr//)
    # filter only numbers on that array
    ->map(call 'filter', \&is_num)
    # pick first and last
    ->map($first_and_last)
    # join every array into string
    ->map(call 'join', "")
    ->do (sub($num)    { printf " %d\n", $num                })
    ->sum;

printf "Sum: %d\n", $sum;

sub digitize($str) {
    state %mapping = (
        one   => 1, two   => 2, three => 3,
        four  => 4, five  => 5, six   => 6,
        seven => 7, eight => 8, nine  => 9,
    );
    my $length = length $str;
    my $new    = "";
    for (my $idx=0; $idx<$length; $idx++) {
        pos($str) = $idx;
        if ( $str =~ m/\G ( [0-9] | one | two | three | four | five | six | seven | eight | nine )/xmsgc ) {
            $new .= is_num($1) ? $1 : $mapping{$1};
        }
    }
    return $new;
}
