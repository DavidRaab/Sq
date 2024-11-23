#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);

sub range_step1($start, $step, $stop) {
    Carp::croak '$step is 0. Will run forever.' if $step == 0;

    # Ascending order
    if ( $start <= $stop ) {
        return Seq::unfold('Seq', $start, sub($current) {
            return $current, $current+$step if $current <= $stop;
            return undef;
        });
    }
    # Descending
    else {
        return Seq::unfold('Seq', $start, sub($current) {
            return $current, $current-$step if $current >= $stop;
            return undef;
        });
    }
}

sub range_step2($start, $step, $stop) {
    Carp::croak '$step is 0. Will run forever.' if $step == 0;

    # Ascending order
    if ( $start <= $stop ) {
        return bless(sub {
            my $abort   = 0;
            my $current = $start;
            my $next    = $current;

            return sub {
                return undef if $abort;
                $current = $next;
                $next   += $step;
                return $current if $current <= $stop;
                $abort = 1;
                return undef;
            }
        }, 'Seq');
    }
    # Descending
    else {
        return bless(sub {
            my $abort   = 0;
            my $current = $start;
            my $next    = $current;

            return sub {
                return undef if $abort;
                $current = $next;
                $next   -= $step;
                return $current if $current >= $stop;
                $abort = 1;
                return undef;
            }
        }, 'Seq');
    }
}

cmpthese(-1, {
    range_step1 => sub { range_step1(1, 1, 10_000)->to_array },
    range_step2 => sub { range_step2(1, 1, 10_000)->to_array },
});