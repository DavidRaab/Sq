#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

print "All defined Array functions:\n\n";
my $funcs = Sq::Reflection::funcs_of('Array');
Sq->fmt->table({
    data => $funcs->sort(by_str)->columns(7),
});

printf "\nTotal defined: %d\n", $funcs->length;
