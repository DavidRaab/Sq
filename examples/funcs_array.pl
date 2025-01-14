#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;

print "All defined Array functions:\n\n";
Sq->fmt->table({
    data => Sq::Reflection::funcs_of('Array')->sort(by_str)->columns(7),
});
