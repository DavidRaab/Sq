#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Benchmark qw(cmpthese);
use Test2::V0;

sub rev($array) {
    my @array;
    my $idx  = $array->$#*;
    while ( $idx >= 0 ) {
        push @array, $array->[$idx--];
    }
    return \@array;
}

my $a1 = [1..100];
my $a2 = [1..10_000];
my $a3 = [1..100_000];

# check if it is really the same
is(rev($a1), [reverse @$a1], 'rev 1');
is(rev($a2), [reverse @$a2], 'rev 2');
is(rev($a3), [reverse @$a3], 'rev 3');

# short check that array did not change
is($a1, [1..100],     'same 1');
is($a2, [1..10_000],  'same 2');
is($a3, [1..100_000], 'same 3');

done_testing();

cmpthese(-1, {
    'own_implementation' => sub {
        my $n1 = rev($a1);
        my $n2 = rev($a2);
        my $n3 = rev($a3);
    },
    'built-in' => sub {
        my $n1 = [ reverse @$a1 ];
        my $n2 = [ reverse @$a2 ];
        my $n3 = [ reverse @$a3 ];
    },
});
