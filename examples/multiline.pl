#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

Sq->fmt->table({
    header => [qw/id text1 text2/],
    data   => [
        [1, "foo", "bar"],
        [2, ["foo", "bar"], "maz"],
        [3, "test", ["maz", "raz"]],
    ],
});

Sq->fmt->table({
    header => [qw/id text1 text2/],
    data   => [
        {id => 1, text1 => "foo",          text2 => "bar"         },
        {id => 2, text1 => ["foo", "bar"], text2 => "maz"         },
        {id => 3, text1 => "test",         text2 => ["maz", "raz"]},
    ],
});
