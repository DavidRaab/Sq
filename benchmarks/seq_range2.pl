#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);

sub range_old($, $start, $stop) {
    return Seq::range_step(undef, $start, 1, $stop);
}

sub range_new($, $start, $stop) {
    $start = int $start;
    $stop  = int $stop;

    # when same return seq with one item
    return Seq->new($start) if $start == $stop;

    # ascending order
    if ( $start < $stop ) {
        return bless(sub {
            my $abort   = 0;
            my $current = $start;
            return sub {
                return undef if $abort;
                if ( $current > $stop ) {
                    $abort = 1;
                    return undef;
                }
                return $current++;
            }
        }, 'Seq');
    }
    # descending order
    else {
        return bless(sub {
            my $abort   = 0;
            my $current = $start;
            return sub {
                return undef if $abort;
                if ( $current < $stop ) {
                    $abort = 1;
                    return undef;
                }
                return $current--;
            }
        }, 'Seq');
    }
}

cmpthese(-1, {
    old_implementation => sub {
        range_old(undef, 1, 10_000)->to_array;
        range_old(undef, 10_000, 1)->to_array;
    },
    new_implementation => sub {
        range_new(undef, 1, 10_000)->to_array;
        range_new(undef, 10_000, 1)->to_array;
    }
});
