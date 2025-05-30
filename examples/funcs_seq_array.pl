#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

my %seq_skip   = map { $_ => 1 } qw/bless blit pop push shift shuffle unshift map_e keep_e/;
my %array_skip = map { $_ => 1 } qw/always cache do doi infinity/;

my $array = Sq::Reflection::funcs_of('Array');
my $seq   = Sq::Reflection::funcs_of('Seq');

print "Seq is missing following Array functions.\n";
$array->diff($seq, \&id)->sort(by_str)->iter(sub($func) {
    return if $seq_skip{$func};
    printf "  + %s\n", $func;
});

print "\nArray is missing following Seq functions.\n";
$seq->diff($array, \&id)->sort(by_str)->iter(sub($func) {
    return if $array_skip{$func};
    printf "  + %s\n", $func;
});
