#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Reflection;
use Sq::Sig;

my $array = all_funcs('Array');
my $seq   = all_funcs('Seq');

print "Array is missing following Array functions.\n";
Hash::difference($seq->count, $array->count)->iter_sort(by_str, sub($key,$) {
    printf "  + %s\n", $key;
});

print "\nSeq is missing following Array functions.\n";
Hash::difference($array->count, $seq->count)->iter_sort(by_str, sub($key,$) {
    printf "  + %s\n", $key;
});

