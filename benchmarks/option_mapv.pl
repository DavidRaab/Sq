#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);

### map, map2 and map_v

my $None = bless([0], 'Option');

sub map($opt, $f) {
    return $opt->[0] == 1
         ? Some( $f->($opt->[1]) )
         : $None;
}

sub map2($optA, $optB, $f) {
    if ( $optA->[0] == 1 && $optB->[0] == 1 ) {
        return Some( $f->($optA->[1], $optB->[1]) );
    }
    return $None;
}

sub map_v {
    my @opts = @_;
    my $f    = pop @opts;

    my @unpack;
    for my $opt ( @opts ) {
        if ( $opt->[0] == 1 ) {
            push @unpack, $opt->[1];
        }
        else {
            return $None;
        }
    }

    return Some($f->(@unpack));
}

### Benchmarks

printf("map vs map_v\n");
my $test = Array->init(10_000, sub($idx) { Some($idx) });
cmpthese(-1, {
    'map' => sub {
        my $add1 = sub($x) { $x + 1 };
        for my $opt ( @$test ) {
            $opt->map($add1);
        }
    },
    'map_v' => sub {
        my $add1 = sub($x) { $x + 1 };
        for my $opt ( @$test ) {
            $opt->map_v($add1);
        }
    }
});

printf("\nmap2 vs map_v\n");
my $test2 = Array->init(10_000, sub($idx) { Some 1 });
cmpthese(-1, {
    'map2' => sub {
        my $add = sub($x,$y) { $x + $y };

        for my $idx ( 0 .. ($test->length-1) ) {
            my $optA = $test ->[$idx];
            my $optB = $test2->[$idx];
            $optA->map2($optB, $add);
        }
    },
    'map_v' => sub {
        my $add = sub($x,$y) { $x + $y };

        for my $idx ( 0 .. ($test->length-1) ) {
            my $optA = $test ->[$idx];
            my $optB = $test2->[$idx];
            $optA->map_v($optB, $add);
        }
    }
});

printf("\nmap3 vs map_v\n");
my $test3 = Array->init(10_000, sub($idx) { Some 1 });
cmpthese(-1, {
    'map3' => sub {
        my $add = sub($x,$y,$z) { $x + $y + $z };

        for my $idx ( 0 .. ($test->length-1) ) {
            my $optA = $test ->[$idx];
            my $optB = $test2->[$idx];
            my $optC = $test3->[$idx];
            $optA->map3($optB, $optC, $add);
        }
    },
    'map_v' => sub {
        my $add = sub($x,$y,$z) { $x + $y + $z };

        for my $idx ( 0 .. ($test->length-1) ) {
            my $optA = $test ->[$idx];
            my $optB = $test2->[$idx];
            my $optC = $test3->[$idx];
            $optA->map_v($optB, $optC, $add);
        }
    }
});