#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Getopt::Long::Descriptive;
use Sq;

# https://adventofcode.com/2023/day/1

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['file|f=s', 'file to work with',  {required     => 1}],
    ['help|h',   'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

my $sum =
    Sq->io->open_text($opt->file)
    ->map(sub($str)    { chomp $str; $str                    })
    ->doi(sub($str,$i) { printf "%4d %s", $i, $str           })
    ->map(sub($line)   { digitize($line)                     })
    ->do( sub($str)    { printf " %s", $str                  })
    ->map(sub($str)    {[ split //, $str                    ]})
    ->map(sub($array)  { Array::filter($array, \&is_num)     })
    ->map(sub($array)  {[ $array->first(0), $array->last(0) ]})
    ->map(sub($array)  { join "", @$array                    })
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
