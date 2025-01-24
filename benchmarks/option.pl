#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;

# Benchmark for checking implementation of either array-ref or
# scalar-ref

# using array to represent option
my $aNone = bless([], 'Option');

sub a_Some :prototype($) ($value)  {
    return defined $value
         ? bless([$value], 'Option')
         : $aNone;
}

sub a_None :prototype() () {
    return $aNone;
}

sub a_iter($opt, $f) {
    $f->($opt->[0]) if @$opt;
}

# using scalar to represent option
my $_None = undef;
my $sNone = bless(\$_None, 'Option');

sub s_Some :prototype($) ($value)  {
    return defined $value
         ? bless(\$value, 'Option')
         : $sNone;
}

sub s_None :prototype() () {
    return $sNone;
}

sub s_iter($opt, $f) {
    $f->($$opt) if defined $$opt;
}

# Testing
my $a = 10;
a_iter(a_Some(1), sub($x) { $a += $x });
a_iter(a_None() , sub($x) { $a += $x });

my $s = 10;
s_iter(s_Some(1), sub($x) { $s += $x });
s_iter(s_None() , sub($x) { $s += $x });

is($a, 11, 'array');
is($s, 11, 'scalar');

done_testing;

# Benchmarks
printf "Benchmark initialization.\n";
Sq->bench->compare(-3, {
    array => sub {
        for ( 1 .. 10_000 ) {
            my $o = a_Some(1);
        }
    },
    scalar => sub {
        for ( 1 .. 10_000 ) {
            my $o = s_Some(1);
        }
    },
});

# creating test optional arrays
my @opt_arrays  = map { a_Some(1) } 1 .. 10_000;
my @opt_scalars = map { s_Some(1) } 1 .. 10_000;

# print memory information when Devel::Size is installed
{
    eval {
        require Devel::Size;
        Devel::Size->import('total_size');
    };
    # when module could be loaded
    if ( $INC{"Devel/Size.pm"} ) {
        print  "\n";
        printf "\@opt_arrays  = %d bytes\n", total_size(\@opt_arrays);
        printf "\@opt_scalars = %d bytes\n", total_size(\@opt_scalars);
    }
    else {
        warn "Install Devel::Size for additional memory information.\n";
    }
}

printf "\nBenchmarking iteration.\n";
Sq->bench->compare(-3, {
    array => sub {
        for my $opt ( @opt_arrays ) {
            a_iter($opt, sub($x) { $x+1 });
        }
    },
    scalar => sub {
        for my $opt ( @opt_scalars ) {
            s_iter($opt, sub($x) { $x+1 });
        }
    },
});