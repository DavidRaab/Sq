#!/usr/bin/env perl
use v5.36;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;
use Sq::Test;
use Getopt::Long::Descriptive;

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
    Sq->fs->read_text($opt->file)
    # splits every string and creates a sequence of arrays
    ->split(qr//)
    # keep only numbers from that array
    ->map(call 'keep', \&is_num)
    # pick first and last item from that array
    ->map($first_and_last)
    # call join on that array to turn to string again
    ->map(call 'join', "")
    # print every entry before summing
    ->doi(sub($num,$idx) { printf "%3d -> %d\n", $idx, $num })
    ->sum;

printf "Sum: %d\n", $sum;
is($sum, 142, 'sum');
done_testing;
