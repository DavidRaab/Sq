#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Reflection;
use Sq::Sig;

print "All defined Array functions:\n\n";
all_funcs('Array')->sort(by_str)->chunked(10)->iter(sub($array) {
    print $array->join(', '), "\n";
});
print "\n";
