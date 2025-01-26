#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
# use Sq -sig => 1;

print "Generating Cache in Memory.\n";
# my $cache = seq { 0 .. 9 }->permute->to_array;
my $cache = Array::permute([0..9]);

Sq->bench->it(sub {
    my @permute = ('A' .. 'J');
    for my $array ( @$cache ) {
        print @permute[@$array], "\n";
    }
});
