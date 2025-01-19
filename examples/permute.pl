#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use Sq::Sig;

sub permute(@items) {
    state $count_up = Sq->math->permute_count_up;
    my $pattern = [(0) x @items];
    my @permute;
    while (1) {
        my @copy = @items;
        my @new;
        for my $idx ( @$pattern ) {
            push @new, splice(@copy, $idx, 1);
        }
        push @permute, \@new;
        last if !$count_up->($pattern);
    }
    return \@permute;
}

dump(permute(qw/A B C D/));