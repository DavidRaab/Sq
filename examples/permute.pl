#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use Sq::Sig;

# Expects an array of int
# For example starts with:
# [0,0,0,0]
sub count_up($array) {
    my $idx = $array->$#*;
    my $max = @$array - ($idx+1);

    UP:
    $array->[$idx]++;
    if ( $array->[$idx] > $max ) {
        $array->[$idx] = 0;
        $idx--;
        return if $idx < 0;
        $max = @$array - ($idx+1);
        goto UP;
    }
    return 1;
}

my $init = [0,0,0,0];
dump($init);
while ( count_up($init) ) {
    dump($init);
}
