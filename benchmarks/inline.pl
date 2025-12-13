#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

my $nums = Sq->rand->int(1,1_000_000)->to_array(10_000);

sub add1($x) { $x + 1 }

Sq->bench->compare(-1, {
    inline => sub {
        my @new = map { $_ + 1 } @$nums;
    },
    no_inline => sub {
        my @new = map { add1($_) } @$nums;
    },
});

