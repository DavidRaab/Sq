#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

say "AoA containing another array";
Sq->fmt->table({
    header => [qw/id text1 text2/],
    data   => [
        [1, "foo", "bar"],
        [2, ["foo", "bar"], "maz"],
        [3, "test", ["maz", "raz"]],
    ],
});

say "AoH containing Arrays";
Sq->fmt->table({
    header => [qw/id text1 text2/],
    data   => [
        {id => 1, text1 => "foo",          text2 => "bar"         },
        {id => 2, text1 => ["foo", "bar"], text2 => "maz"         },
        {id => 3, text1 => "test",         text2 => ["maz", "raz"]},
    ],
});

say "Seq of Array: Containg Arrays";
Sq->fmt->table({
    header => [qw/id text1 text2/],
    data   => seq {
        [1, "foo", "bar"],
        [2, ["foo", "bar"], "maz"],
        [3, "test", ["maz", "raz"]],
    },
});

say "Seq of Hash: Containing Arrays";
Sq->fmt->table({
    header => [qw/id text1 text2/],
    data   => seq {
        {id => 1, text1 => "foo",          text2 => "bar"         },
        {id => 2, text1 => ["foo", "bar"], text2 => "maz"         },
        {id => 3, text1 => "test",         text2 => ["maz", "raz"]},
    },
});

say "Seq of Hash: Containing Strings with newlines";
Sq->fmt->table({
    header => [qw/id text1 text2/],
    data   => seq {
        {id => 1, text1 => "foo",      text2 => "bar"      },
        {id => 2, text1 => "foo\nbar", text2 => "maz"      },
        {id => 3, text1 => "test",     text2 => "maz\nraz" },
    },
});

say "Seq of Hash: Containing newline Strings and Arrays, No Header defined";
Sq->fmt->table({
    data => seq {
        {id => 1, text1 => "foo",      text2 => "bar"                     },
        {id => 2, text1 => "foo\nbar", text2 => "maz",        Awesome => 2},
        {id => 3, text1 => "test",     text2 => [qw/maz raz/]             },
    },
});