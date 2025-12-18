#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

Sq->fmt->table({
    header => [qw/Array Sum Count Mean/],
    data   =>
        Array
        ->init(10, sub($i) { Array->range(1,$i+1) })
        ->map(     sub($a) { [Str->collapse(dumps($a)), $a->sum, $a->length, $a->mean] }),
});
