#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

Sq->fmt->new_table({
    columns => [20,10,8],
    data => [
        ["foo", "bar", "baz"],
        [qw/123445/],
    ],
});
