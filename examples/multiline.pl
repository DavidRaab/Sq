#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

Sq->fmt->table({
    title  => "AoA containing another array",
    header => [qw/id text1 text2/],
    data   => [
        [1, "foo", "bar"],
        [2, ["foo", "bar"], "maz"],
        [3, "test", ["maz", "raz"]],
    ],
});

Sq->fmt->table({
    title  => "AoH containing Arrays",
    header => [qw/id text1 text2/],
    data   => [
        {id => 1, text1 => "foo",          text2 => "bar"         },
        {id => 2, text1 => ["foo", "bar"], text2 => "maz"         },
        {id => 3, text1 => "test",         text2 => ["maz", "raz"]},
    ],
});

Sq->fmt->table({
    title  => "Seq of Array: Containg Arrays",
    header => [qw/id text1 text2/],
    data   => seq(
        [1, "foo", "bar"],
        [2, ["foo", "bar"], "maz"],
        [3, "test", ["maz", "raz"]],
    ),
});

Sq->fmt->table({
    title  => "Seq of Hash: Containing Arrays",
    header => [qw/id text1 text2/],
    data   => seq(
        {id => 1, text1 => "foo",          text2 => "bar"         },
        {id => 2, text1 => ["foo", "bar"], text2 => "maz"         },
        {id => 3, text1 => "test",         text2 => ["maz", "raz"]},
    ),
});

Sq->fmt->table({
    title  => "Seq of Hash: Containing Strings with newlines",
    header => [qw/id text1 text2/],
    data   => seq(
        {id => 1, text1 => "foo",      text2 => "bar"      },
        {id => 2, text1 => "foo\nbar", text2 => "maz"      },
        {id => 3, text1 => "test",     text2 => "maz\nraz" },
    ),
});

Sq->fmt->table({
    title => "Seq of Hash: Containing newline Strings and Arrays, No Header defined",
    data  => seq(
        {id => 1, text1 => "foo",      text2 => "bar"                     },
        {id => 2, text1 => "foo\nbar", text2 => "maz",        Awesome => 2},
        {id => 3, text1 => "test",     text2 => [qw/maz raz/]             },
    ),
});
