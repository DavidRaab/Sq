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
    ->str_split(qr//)
    ->map( sub($array)    { Array::filter($array, \&is_num)       })
    ->map( sub($array)    { [ $array->first(0), $array->last(0) ] })
    ->map( sub($array)    { join "", @$array                      })
    ->doi( sub($idx,$num) { printf "%3d -> %d\n", $idx, $num      })
    ->sum;

printf "Sum: %d\n", $sum;
