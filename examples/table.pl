#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

# Table with Array of Array
Sq->fmt->table({
    data => [
        [1,2,3],
        [1,2,3,4],
        [1,2]
    ],
});

say "";

# Table with Array of Hashes
fn user => record(qw/id name points/);
Sq->fmt->table({
    header => [qw/id name points/],
    data   => [
        user(1, "Anny",  100),
        user(2, "Lilly",  99),
        user(3, "Angel", 101),
        {id => 4, name => "Lena"},
    ],
});
