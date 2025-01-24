#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use Benchmark qw(cmpthese);

sub min1($array) {
    my $len = @$array;
    return Option::None()            if $len == 0;
    return Option::Some($array->[0]) if $len == 1;

    my $min = $array->[0];
    for (my $idx=1; $idx < $array->$#*; $idx++ ) {
        my $x = $array->[$idx];
        $min = $x if $x < $min;
    }
    return Option::Some($min);
}

sub min2($array) {
    my $min = undef;
    for my $x ( @$array ) {
        if ( defined $min ) {
            $min = $x if $x < $min;
        }
        else {
            $min = $x;
        }
    }
    return Option::Some($min);
}

sub min3($array) {
    return Option::None() if @$array == 0;
    my $min = $array->[0];
    for my $x ( @$array ) {
        $min = $x if $x < $min;
    }
    return Option::Some($min);
}

# Testing
my @funcs = qw(min1 min2 min3);
my $data = Array->range(1,10_000);
$data->shuffle;
for my $func ( @funcs ) {
    no strict 'refs'; ## no critic
    my $fn = *{$func}{CODE};
    is($fn->([]),       None, "check $func on []");
    is($fn->($data), Some(1), "check $func");
}
done_testing;

# Benchmarking
cmpthese(-2, {
    min1    => sub { my $min = min1($data) },
    min2    => sub { my $min = min2($data) },
    min3    => sub { my $min = min3($data) },
    current => sub { my $min = Array::min($data) },
});
