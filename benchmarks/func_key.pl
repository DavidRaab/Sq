#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Test2::V0;
use Benchmark qw(cmpthese);

sub key1 :prototype($) {
    my $name = $_[0];
    return sub($hash) { return $hash->{$name} };
}

sub key2 :prototype($) {
    state %cache;
    my $name = $_[0];

    # return cached sub
    my $func = $cache{$name};
    return $func if defined $func;

    # otherwise create/store new sub
    $func = sub($hash) { return $hash->{$name} };
    $cache{$name} = $func;
    return $func;
}

# what to Benchmark, but data are passed as argument.
sub bench($data) {
    cmpthese(-1, {
        inline => sub {
            for ( 1 .. 1_000 ) {
                my $max = $data->max_by(sub($hash) { $hash->{num} })
            }
        },
        inline_cache => sub {
            my $num = sub($hash) { $hash->{num} };
            for ( 1 .. 1_000 ) {
                my $max = $data->max_by($num);
            }
        },
        key1 => sub {
            for ( 1 .. 1_000 ) {
                my $max = $data->max_by(key1 'num')
            }
        },
        key2 => sub {
            for ( 1 .. 1_000 ) {
                my $max = $data->max_by(key2 'num')
            }
        },
        key2_cache => sub {
            my $num = key2 'num';
            for ( 1 .. 1_000 ) {
                my $max = $data->max_by($num);
            }
        },
        current => sub {
            for ( 1 .. 1_000 ) {
                my $max = $data->max_by(key 'num')
            }
        }
    });
}

print "\nData with 1000 elements\n";
bench(
    Seq->init(1000, sub($idx) {
        sq { id => $idx, num => rand(100_000) }
    })->to_array
);

print "\nData with 100 elements\n";
bench(
    Seq->init(100, sub($idx) {
        sq { id => $idx, num => rand(100_000) }
    })->to_array
);

print "Data with 10 elements\n";
bench(
    Seq->init(10, sub($idx) {
        sq { id => $idx, num => rand(100_000) }
    })->to_array
);
