#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;

print "All defined Array functions:\n\n";
my $count = 1;
sq([Sq::Reflection::all_funcs('Array')])->sort_str->chunked(10)->iter(sub($array) {
    print $array->join(', '), "\n";
});
print "\n";
