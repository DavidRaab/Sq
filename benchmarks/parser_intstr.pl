#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Parser;
use Sq::Test;

# Benchmark that test performance of p_str with multiple values compared
# to using p_or( p_str, p_str )

my $int1 = p_many(p_or(map { p_strc($_) } 0 .. 9));
my $int2 = p_many(p_strc(qw/0 1 2 3 4 5 6 7 8 9/));

my $str = '12345';
is(p_run($int1, $str), Some([1,2,3,4,5]), '$int1');
is(p_run($int2, $str), Some([1,2,3,4,5]), '$int2');
done_testing;

Sq->bench->compare(-1, {
    int1 => sub { for ( 1 .. 1_000 ) { my $r = p_run($int1, $str) } },
    int2 => sub { for ( 1 .. 1_000 ) { my $r = p_run($int2, $str) } },
});
