#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Gen;
use Sq::Test;
use Sq::Sig;

sub regex1($any) {
    return $any =~ m/\A[-+]?\d+\z/ ? 1 : 0;
}

sub regex2($any) {
    return $any =~ m/\A[-+]?[0-9]+\z/ ? 1 : 0;
}

sub regex3($any) {
    return $any =~ m/\A[-+]?\d++\z/ ? 1 : 0;
}

sub regex4($any) {
    return $any =~ m/\A(?>[-+]?)[0-9]++\z/ ? 1 : 0;
}

sub num($any) {
    if ( is_num($any) ) {
        return $any =~ m/\A[-+]?[0-9]+\z/ ? 1 : 0;
    }
    return 0;
}

sub byref($any) {
    if ( ref $any eq "" ) {
        return $any =~ m/\A[-+]?[0-9]+\z/ ? 1 : 0;
    }
}

# Generates Array with 1_000 elements, 250 at least are int
my $strs   = gen [repeat => 250, [str   => 5, 20]];
my $ints   = gen [repeat => 250, [int   => 0, 10_000]];
my $floats = gen [repeat => 250, [float => 0, 10_000]];
my $arrays = gen [repeat => 250, ['array']];
my $data   = Array::shuffle(Array::flatten(
    gen_run gen [array => $strs, $ints, $floats, $arrays]
));

# dump($data);

# Test if all return the same
is($data->keep(\&regex1), $data->keep(\&regex2), 'regex1 vs regex2');
is($data->keep(\&regex2), $data->keep(\&regex3), 'regex2 vs regex3');
is($data->keep(\&regex3), $data->keep(\&num),    'regex4 vs num');
is($data->keep(\&num),    $data->keep(\&byref),  'num vs byref');
done_testing;

# Benchmark
Sq->bench->compare(-1, {
    regex1 => sub {
        for my $x ( @$data ) {
            regex1($x);
        }
    },
    regex2 => sub {
        for my $x ( @$data ) {
            regex2($x);
        }
    },
    regex3 => sub {
        for my $x ( @$data ) {
            regex3($x);
        }
    },
    regex4 => sub {
        for my $x ( @$data ) {
            regex4($x);
        }
    },
    num => sub {
        for my $x ( @$data ) {
            num($x);
        }
    },
    byref => sub {
        for my $x ( @$data ) {
            byref($x);
        }
    }
});