#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Parser;
use Test2::V0;
use Benchmark qw(cmpthese);

sub pstr_1($string) {
    return sub($ctx,$str) {
        pos($str) = $ctx->{pos};
        if ( $str =~ m/\G\Q$string\E/gc ) {
            return Some([
                Hash::withf($ctx, pos => sub { pos($str) }),
                $string
            ]);
        }
        return None;
    }
}

sub pstr_2($string) {
    return sub($ctx,$str) {
        my $length = length $string;
        if ( $string eq substr($str, $ctx->{pos}, $length) ) {
            return Some([
                Hash::withf($ctx, pos => sub { $_[0] + $length }),
                $string
            ]);
        }
        return None;
    }
}

sub pstr_3($string) {
    return sub($ctx,$str) {
        my $length = length $string;
        if ( $string eq substr($str, $ctx->{pos}, $length) ) {
            return Some([
                { %$ctx, pos => $ctx->{pos} + $length },
                $string
            ]);
        }
        return None;
    }
}

# Tests
my @funcs = (qw/pstr_1 pstr_2 pstr_3/);
for my $func ( @funcs ) {
    no strict 'refs';
    my $fn = *{$func}{CODE};
    my $af = p_and(map { $fn->($_) } "a" .. "f");
    is(p_run($af, "abcdef"), Some(['a' .. 'f']), 'a .. f');
}
done_testing;

# Benchmark
my $afc = p_and(map { p_strc($_) } "a" .. "f");
my $af1 = p_and(map { pstr_1($_) } "a" .. "f");
my $af2 = p_and(map { pstr_2($_) } "a" .. "f");
my $af3 = p_and(map { pstr_3($_) } "a" .. "f");

my $str = 'abcdef';
cmpthese(-1, {
    pstr_1  => sub { for ( 1 .. 1_000) { my $r = p_run($af1, $str) } },
    pstr_2  => sub { for ( 1 .. 1_000) { my $r = p_run($af2, $str) } },
    pstr_3  => sub { for ( 1 .. 1_000) { my $r = p_run($af3, $str) } },
    current => sub { for ( 1 .. 1_000) { my $r = p_run($afc, $str) } },
});
