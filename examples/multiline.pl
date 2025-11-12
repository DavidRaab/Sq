#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

Sq->fmt->table({
    header => [qw/id text/],
    data   => [
        [1, "foo", "bar"],
        [2, ["foo", "bar"], "maz"],
        [3, "test", ["maz", "raz"]],
    ],
});
