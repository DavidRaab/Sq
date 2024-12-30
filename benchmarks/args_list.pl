#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Benchmark qw(cmpthese);

# What is better?
# Calling a function with 1,000 arguments. Or calling a single function
# 1,000 times per each argument? I guess the first, but how well does
# it work with a lot of arguments?

sub sq1 :prototype($);
sub sq1 :prototype($) {
    my ( $any ) = @_;
    my $type = ref $any;

    # Add Array/Hash blessing to current ref
    CORE::bless($any, 'Array'), $type = 'Array' if $type eq 'ARRAY';
    CORE::bless($any, 'Hash'),  $type = 'Hash'  if $type eq 'HASH';

    # recursively go through each data-structure
    if ( $type eq 'Hash' ) {
        for my $value ( values %$any ) {
            sq1 $value;
        }
    }
    elsif ( $type eq 'Array' ) {
        for my $x ( @$any ) { sq1 $x }
    }
    elsif ( $type eq 'Option' ) {
        for my $x ( @$any ) { sq1 $x }
    }
    elsif ( $type eq 'Result' ) {
        sq1 $any->[1];
    }
    else {
        # Do nothing for unknown type
    }
    return $any;
}

sub sq2 (@anys) {
    for my $any ( @anys ) {
        my $type = ref $any;

        # Add Array/Hash blessing to current ref
        CORE::bless($any, 'Array'), $type = 'Array' if $type eq 'ARRAY';
        CORE::bless($any, 'Hash'),  $type = 'Hash'  if $type eq 'HASH';

        # recursively go through each data-structure
        if ( $type eq 'Hash' ) {
            sq2(values %$any);
        }
        elsif ( $type eq 'Array' ) {
            sq2(@$any);
        }
        elsif ( $type eq 'Option' ) {
            sq2(@$any);
        }
        elsif ( $type eq 'Result' ) {
            sq2($any->[1]);
        }
        else {
            # Do nothing for unknown type
        }
    }
    return @anys;
}

sub sq3 (@anys) {
    for my $any ( @anys ) {
        my $type = ref $any;

        # Add Array/Hash blessing to current ref
        CORE::bless($any, 'Array'), $type = 'Array' if $type eq 'ARRAY';
        CORE::bless($any, 'Hash'),  $type = 'Hash'  if $type eq 'HASH';

        # recursively go through each data-structure
        if ( $type eq 'Hash' ) {
            sq3(values %$any);
        }
        elsif ( $type eq 'Array' ) {
            sq3(@$any);
        }
        elsif ( $type eq 'Option' ) {
            sq3(@$any);
        }
        elsif ( $type eq 'Result' ) {
            sq3($any->[1]);
        }
        else {
            # Do nothing for unknown type
        }
    }
    return @anys;
}

sub bench($data) {
    cmpthese(-1, {
        sq1 => sub {
            my $d = sq1($data);
        },
        sq2 => sub {
            my @d = sq2(@$data);
        },
        sq3 => sub {
            my @d = sq3(@$data);
        }
    });
}

print "Benchmarking 100 elements\n";
bench([map { +{ id => 1, name => "foo" }} 1 .. 100]);

print "\nBenchmarking 1_000 elements\n";
bench([map { +{ id => 1, name => "foo" }} 1 .. 1_000]);

print "\nBenchmarking 10_000 elements\n";
bench([map { +{ id => 1, name => "foo" }} 1 .. 10_000]);

print "\nBenchmarking 100_000 elements\n";
bench([map { +{ id => 1, name => "foo" }} 1 .. 100_000]);