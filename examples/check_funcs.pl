#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Reflection;
use Sq::Sig;

my %seq_skip   = map { $_ => 1 } qw/bless blit pop push shift shuffle unshift map_e filter_e/;
my %array_skip = map { $_ => 1 } qw/always cache do doi infinity/;

my $array = all_funcs('Array');
my $seq   = all_funcs('Seq');

print "Array is missing following Array functions.\n";
Hash::difference($seq->count, $array->count)->keys->remove(sub($func) {
    $array_skip{$func}
})->sort(by_str)->iter(sub($func) {
    printf "  + %s\n", $func;
});

print "\nSeq is missing following Array functions.\n";
Hash::difference($array->count, $seq->count)->keys->remove(sub($func) {
    $seq_skip{$func}
})->sort(by_str)->iter(sub($func) {
    printf "  + %s\n", $func;
});

