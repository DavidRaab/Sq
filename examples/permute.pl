#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
#use Sq -sig => 1;
use Sq;

my $count = 0;
Sq->bench->it(sub {
    seq(qw/A B C D E F G H I J/)->permute->iter(sub($array) {
        $count++;
        say $array->join("");
    });
});

say "Count should be: ", Sq->math->fac(10);
say "Count: $count";
