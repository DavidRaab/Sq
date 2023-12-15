#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Getopt::Long::Descriptive;
use Sq;

# https://adventofcode.com/2023/day/1

my $sum =
    Sq->io->open_text("01.txt")
    ->str_split(qr//)
    ->map( sub($array)    { Array::filter($array, \&is_num)       })
    ->map( sub($array)    { [ $array->first(0), $array->last(0) ] })
    ->map( sub($array)    { join "", @$array                      })
    ->doi( sub($idx,$num) { printf "%3d -> %d\n", $idx, $num      })
    ->sum;

printf "Sum: %d\n", $sum;

# $file->iter(sub($line) { print $line });