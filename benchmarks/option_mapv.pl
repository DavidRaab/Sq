#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);
use Test2::V0;

### map, map2 and map_v

my $None = bless([0], 'Option');

sub map1($opt, $f) {
    return $opt->[0] == 1
         ? Some $f->($opt->[1])
         : $None;
}

sub map2($optA, $optB, $f) {
    if ( $optA->[0] == 1 && $optB->[0] == 1 ) {
        return Some $f->($optA->[1], $optB->[1]);
    }
    return $None;
}

sub map3($optA, $optB, $optC, $f) {
    if ( $optA->[0] == 1 && $optB->[0] == 1 && $optC->[0] == 1 ) {
        return Some $f->($optA->[1], $optB->[1], $optC->[1]);
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

# same as map_v2 but uses array indexes instead of pop
sub map_v2 {
    my $f = $_[-1];

    my $max = @_ - 2;
    my @unpack;
    for (my $idx=0; $idx <= $max; $idx++) {
        if ( $_[$idx][0] == 1 ) {
            push @unpack, $_[$idx][1];
        }
        else {
            return $None;
        }
    }

    return Some($f->(@unpack));
}

## Some tests
is(map_v (Some 1, Some 2, sub($x,$y) { $x + $y }), Some(3), 'map_v');
is(map_v2(Some 1, Some 2, sub($x,$y) { $x + $y }), Some(3), 'map_v2');
is(map_v2(Some 1, Some 2, Some 3, sub($x,$y,$z) { $x + $y + $z }), Some(6), 'map_v2');
done_testing;

### Benchmarks

printf("map vs map_v\n");
my $test = Array->init(10_000, sub($idx) { Some($idx) });
cmpthese(-1, {
    'map' => sub {
        my $add1 = sub($x) { $x + 1 };
        for my $opt ( @$test ) {
            map1($opt, $add1);
        }
    },
    'map_v' => sub {
        my $add1 = sub($x) { $x + 1 };
        for my $opt ( @$test ) {
            map_v($opt, $add1);
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
            map2($optA, $optB, $add);
        }
    },
    'map_v' => sub {
        my $add = sub($x,$y) { $x + $y };

        for my $idx ( 0 .. ($test->length-1) ) {
            my $optA = $test ->[$idx];
            my $optB = $test2->[$idx];
            map_v($optA, $optB, $add);
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
            map3($optA, $optB, $optC, $add);
        }
    },
    'map_v' => sub {
        my $add = sub($x,$y,$z) { $x + $y + $z };

        for my $idx ( 0 .. ($test->length-1) ) {
            my $optA = $test ->[$idx];
            my $optB = $test2->[$idx];
            my $optC = $test3->[$idx];
            map_v($optA, $optB, $optC, $add);
        }
    }
});

printf("\nmap_v vs map_v2\n");
cmpthese(-1, {
    map_v => sub {
        my $add1 = sub($x) { $x + 1 };
        for my $opt ( @$test ) {
            map_v($opt, $add1);
        }
    },
    map_v2 => sub {
        my $add1 = sub($x) { $x + 1 };
        for my $opt ( @$test ) {
            map_v2($opt, $add1);
        }
    }
});