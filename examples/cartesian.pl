#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

sub cartesian(@arrays) {
    state $count_up = sub($max, $counter) {
        my $idx = $counter->$#*;
        UP:
        $counter->[$idx]++;
        if ( $counter->[$idx] >= $max->[$idx] ) {
            $counter->[$idx] = 0;
            $idx--;
            return 0 if $idx < 0;
            goto UP;
        }
        return 1;
    };

    my $maxs    = Array::map(\@arrays, call 'length');
    my $counter = [(0) x (scalar @arrays)];
    my @new     = [map { $_->[0] } @arrays];
    while ( $count_up->($maxs, $counter) ) {
        my @inner;
        for (my $aidx=0; $aidx < @arrays; $aidx++) {
            push @inner, $arrays[$aidx][$counter->[$aidx]];
        }
        push @new, CORE::bless(\@inner, 'Array');
    }
    return CORE::bless(\@new, 'Array');
}

dump(cartesian([1..10], [qw/J Q K A/], [qw/C G T/]));
