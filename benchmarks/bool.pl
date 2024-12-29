#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;
use Sq::Type;
use Sq::Test;
use Benchmark qw(cmpthese);

my @inputs = (0, 10, "foo", -1, undef, [], 1, {});

cmpthese(-1, {
    regex => sub {for ( 1 .. 1_000 ) {
        my $count = 0;
        for my $in ( @inputs ) {
            $count++ if defined $in && $in =~ m/\A[01]\z/;
        }
        die "\$count not 2\n" if $count != 2;
    }},
    num => sub {for ( 1 .. 1_000 ) {
        my $count = 0;
        for my $in ( @inputs ) {
            $count++ if Scalar::Util::looks_like_number($in) && ($in == 0 || $in == 1);
        }
        die "\$count not 2\n" if $count != 2;
    }},
    is_num => sub {for ( 1 .. 1_000 ) {
        my $count = 0;
        for my $in ( @inputs ) {
            $count++ if is_num($in) && ($in == 0 || $in == 1);
        }
        die "\$count not 2\n" if $count != 2;
    }},
    length => sub {for ( 1 .. 1_000 ) {
        my $count = 0;
        for my $in ( @inputs ) {
            $count++ if
                defined $in
                && length($in) == 1
                && Scalar::Util::looks_like_number($in)
                && ($in == 0 || $in == 1);
        }
        die "\$count not 2\n" if $count != 2;
    }},
    ref => sub {for ( 1 .. 1_000 ) {
        my $count = 0;
        for my $in ( @inputs ) {
            $count++ if
                ref $in eq ""
                && Scalar::Util::looks_like_number($in)
                && ($in == 0 || $in == 1);
        }
        die "\$count not 2\n" if $count != 2;
    }},
});