#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use List::Util qw(shuffle);

# swap every element with a random new one
sub shuffle1($array) {
    my @new = @$array;
    my $max = @$array;
    my ($new_idx, $tmp);
    for ( my $idx=0; $idx < $max; $idx++ ) {
        $new_idx       = rand($max);
        $tmp           = $new[$idx];
        $new[$idx]     = $new[$new_idx];
        $new[$new_idx] = $tmp;
    }
    return bless(\@new, 'Array');
}

# from List::Util
sub shuffle2_a($array) {
    CORE::bless([List::Util::shuffle @$array], 'Array');
}

sub shuffle2_b($array) {
    my $new = [List::Util::shuffle @$array];
    CORE::bless($new, 'Array');
}

sub shuffle2_c($array) {
    my @new = List::Util::shuffle @$array;
    CORE::bless(\@new, 'Array');
}

# shuffle like selection sort
sub shuffle3($array) {
    my @new  = @$array;
    my $max  = @$array;
    my ($tmp, $offset);
    for ( my $idx=0; $idx < $max; $idx++ ) {
        $offset        = rand($max - $idx);
        $tmp           = $new[$idx];
        $new[$idx]     = $new[$idx + $offset];
        $new[$idx+$offset] = $tmp;
    }
    return bless(\@new, 'Array');
}

# my $data = [1..10];
# for ( 1 .. 1_000 ) {
#     dump(shuffle3($data));
#     if ( Array::sum($data) != 55 ) {
#         warn "Error: %s\n", dumps($data);
#     }
# }

# "shuffle2" here is ~60% faster compared to "current". Why?
# Array::shuffle is exactly implemented as shuffle2().

my $array = Array->range(1,100);
Sq->bench->compare(-1, {
    current  => sub {
        for ( 1 .. 1_000 ) {
            my $s = Array::shuffle($array);
        }
    },
    shuffle1 => sub {
        for ( 1 .. 1_000 ) {
            my $s = shuffle1($array);
        }
    },
    shuffle2_a => sub {
        for ( 1 .. 1_000 ) {
            my $s = shuffle2_a($array);
        }
    },
    shuffle2_b => sub {
        for ( 1 .. 1_000 ) {
            my $s = shuffle2_b($array);
        }
    },
    shuffle2_c => sub {
        for ( 1 .. 1_000 ) {
            my $s = shuffle2_c($array);
        }
    },
    shuffle3 => sub {
        for ( 1 .. 1_000 ) {
            my $s = shuffle3($array);
        }
    },
});
