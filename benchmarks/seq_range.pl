#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);

sub range1($, $start, $stop) {
    return Seq::range_step(undef, $start, 1, $stop);
}

sub range2($, $start, $stop) {
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
    range1 => sub {
        range1(undef, 1, 10_000)->to_array;
        range1(undef, 10_000, 1)->to_array;
    },
    range2 => sub {
        range2(undef, 1, 10_000)->to_array;
        range2(undef, 10_000, 1)->to_array;
    }
});
