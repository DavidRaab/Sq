#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);
use Test2::V0;

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

# Testing
my @funcs = qw(range1 range2);
my $asc   = Array->range(1, 100);
my $dsc   = Array->range(100, 1);
for my $func ( @funcs ) {
    no strict 'refs';
    my $fn = *{$func}{CODE};
    is($fn->(undef, 1, 100)->to_array, $asc, "check asc $func");
    is($fn->(undef, 100, 1)->to_array, $dsc, "check dsc $func");
}
done_testing;

# Benchmarks
cmpthese(-1, {
    range1 => sub {
        range1(undef, 1, 10_000)->to_array;
        range1(undef, 10_000, 1)->to_array;
    },
    range2 => sub {
        range2(undef, 1, 10_000)->to_array;
        range2(undef, 10_000, 1)->to_array;
    },
    current => sub {
        Seq::range(undef, 1, 10_000)->to_array;
        Seq::range(undef, 10_000, 1)->to_array;
    }
});
