#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Parser;
use Sq::Test;
use Benchmark qw(cmpthese);

# Benchmark that shows two different ways to get the same result. Mainly
# allowing - and _ in an integer and throw those extra characters away.

sub result(@xs) { Some([@xs]) }

my $int1 =
    p_join('',
        p_keep(
            p_split('',
                p_match(qr/([0-9-_]+)/)),
            sub($x) { $x =~ m/[0-9]/ }));

my $int2 = p_matchf    (qr/([0-9-_]+)/, sub($str) {      $str =~ s/[-_]+//gr  });
my $int3 = p_matchf_opt(qr/([0-9-_]+)/, sub($str) { Some($str =~ s/[-_]+//gr) });

# Testing if the same.
for my $int ( $int1, $int2, $int3 ) {
    is(p_run($int, '1000'),         result("1000"), 'int 1');
    is(p_run($int, '1_000'),        result("1000"), 'int 2');
    is(p_run($int, '-1-0-0-0-'),    result("1000"), 'int 3');
    is(p_run($int, '1-00-00'),     result("10000"), 'int 4');
    is(p_run($int, '1_000_000'), result("1000000"), 'int 5');
}
done_testing;

cmpthese(-3, {
    int1_complex    => sub { for ( 1 .. 1_000 ) { my $x = p_run($int1, '1-00-00') } },
    int2_matchf     => sub { for ( 1 .. 1_000 ) { my $x = p_run($int2, '1-00-00') } },
    int3_matchf_opt => sub { for ( 1 .. 1_000 ) { my $x = p_run($int3, '1-00-00') } },
});
