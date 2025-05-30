#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
# use Sq -sig => 1;
use List::MoreUtils qw(natatime);

sub splice_mojo(@pairs) {
    my @cookies;
    while (my ($name, $value) = splice @pairs, 0, 2) {
        push @cookies, {name => $name, value => $value };
    }
}

sub index_based1(@pairs) {
    my (@cookies, $name, $value);
    my $idx = 0;
    my $max = @pairs;
    while ( $idx < $max ) {
        ($name, $value) = @pairs[$idx, $idx+1];
        push @cookies, {name => $name, value => $value};
        $idx += 2;
    }
}

sub index_based2(@pairs) {
    my (@cookies, $name, $value);
    my $idx = 0;
    my $max = @pairs;
    while ( $idx < $max ) {
        $name  = $pairs[$idx];
        $value = $pairs[$idx+1];
        push @cookies, {name => $name, value => $value};
        $idx += 2;
    }
}

sub builtin(@pairs) {
    my @cookies;
    # Added with 5.036; not experimental anymore with 5.040
    for my ($name,$value) ( @pairs ) {
        push @cookies, {name => $name, value => $value};
    }
}

sub chunked(@pairs) {
    Array::chunked(\@pairs, 2)->iter(sub {});
}

# Not the same, but i am curious about performance
sub windowed(@pairs) {
    Array::windowed(\@pairs, 2);
}

my @data = map { (foo => $_) } 1 .. 100;
Sq->bench->compare(-1, {
    splice1 => sub {
        for ( 1 .. 1_000 ) {
            splice_mojo(@data);
        }
    },
    index_based1 => sub {
        for ( 1 .. 1_000 ) {
            index_based1(@data);
        }
    },
    index_based2 => sub {
        for ( 1 .. 1_000 ) {
            index_based2(@data);
        }
    },
    builtin => sub {
        for ( 1 .. 1_000 ) {
            builtin(@data);
        }
    },
    chunked => sub {
        for ( 1 .. 1_000 ) {
            chunked(@data);
        }
    },
    natatime => sub {
        for ( 1 .. 1_000 ) {
            my $it = natatime 2, @data;
            while ( my @vals = $it->() ) {
            }
        }
    },
    windowed => sub {
        for ( 1 .. 1_000 ) {
            windowed(@data);
        }
    },
    current => sub {
        for ( 1 .. 1_000 ) {
            Array::itern(\@data, 2, sub {});
        }
    },
});