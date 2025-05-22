#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

Sq->fmt->table({
    data =>
        Array::cartesian([1..10], [qw/J Q K A/], [qw/C G T/])
        ->map(call 'join', ',')
        ->columns(10),
});
