#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use DDP;
use Sq;
use Benchmark qw(cmpthese);
use Test2::V0;

sub append_1($hashA, $hashB) {
    my %new = %$hashA;
    while ( my ($key,$value) = each %$hashB ) {
        $new{$key} = $value;
    }
    return CORE::bless(\%new, 'Hash');
}

sub append_2($hash, $other) {
    state $second = sub($,$y) { return $y };
    return Hash::union($hash, $other, $second);
}

# this does not work
sub append_3($hashA, $hashB) {
    my %new = %$hashA;
    # this overwrites %new
       %new = %$hashB;
    return bless(\%new, 'Hash');
}

# initializing of hashes for testing
my $hashA = Hash->init(1000, sub($idx) {
    return rand_string(4), rand 10_000;
});
my $hashB = Hash->init(1000, sub($idx) {
    return rand_string(4), rand 10_000;
});

is(
    append_1($hashA, $hashB),
    append_2($hashA, $hashB),
    'append_1 same as append_2');
done_testing;

# Benchmark
cmpthese(-2, {
    'append_1' => sub { append_1($hashA, $hashB) },
    'append_2' => sub { append_2($hashA, $hashB) },
});


# Helper to build random string
sub rand_char() {
    state @chars = ( 'a' .. 'z', 'A' .. 'Z' );
    state $max   = @chars - 1;
    return $chars[rand($max)];
}

sub rand_string($count) {
    my $str = "";
    for ( 1 .. $count ) {
        $str .= rand_char();
    }
    return $str;
}
