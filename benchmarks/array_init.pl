#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);

sub init_seq($count, $f) {
    local $_;
    my @new =
        grep { defined  }
        map  { $f->($_) } 0 .. ($count-1);
    return CORE::bless(\@new, 'Array');
}

sub init_seq_inline($count, $f) {
    local $_;
    return CORE::bless([
        grep { defined  }
        map  { $f->($_) }
            0 .. ($count-1)
    ], 'Array');
}

sub init_inside($count, $f) {
    local $_;
    my @new = map { grep { defined } $f->($_) } 0 .. ($count-1);
    return CORE::bless(\@new, 'Array');
}

my $amount = 10_000;
cmpthese(-2, {
    init_seq  => sub {
        init_seq($amount, sub($x) {
            return undef if rand() < 0.01;
            return 1;
        });
    },
    init_seq_inline  => sub {
        init_seq_inline($amount, sub($x) {
            return undef if rand() < 0.01;
            return 1;
        });
    },
    init_inside => sub {
        init_inside($amount, sub($x) {
            return undef if rand() < 0.01;
            return 1;
        });
    },
});