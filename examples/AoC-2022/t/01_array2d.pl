#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
# use FindBin qw($RealBin);
# use lib "$RealBin/../";
use lib "/home/david/src/playground/AoC-2022";
use Test2::V0;
use Array2D;
no warnings 'experimental::signatures';

# check from_aoa
my $a = Array2D->from_aoa([
    [1,2,3],
    [4,5,6],
    [7,8,9],
]);

is($a->width,  3, "a width");
is($a->height, 3, "a height");
is($a->get(0,0), 1, "0,0 is 1");
is($a->get(2,0), 3, "2,0 is 3");
is($a->get(1,1), 5, "1,1 is 5");
is($a->get(0,2), 7, "0,2 is 7");
is($a->get(2,2), 9, "2,2 is 9");

# check init
my $b = Array2D->init(5, 5, sub($x,$y){ [$x,$y] });
is($b->width,  5, "b width");
is($b->height, 5, "b height");
for my $x ( 0 .. $b->width-1 ) {
    for my $y ( 0 .. $b->height-1 ) {
        is($b->get($x,$y), [$x,$y], "b check $x,$y");
    }
}

# check map
my $c = $b->map(sub($val){ $val->[0] + $val->[1] });
is($c->width,  5, "c width");
is($c->height, 5, "c height");
for my $x ( 0 .. $c->width-1 ) {
    for my $y ( 0 .. $c->height-1 ) {
        is($c->get($x,$y), $x+$y, "c check $x,$y");
    }
}

# check reduce
my $sum = $c->reduce(0, sub($acc, $value, $x, $y) { $acc + $value });
is($sum, 100, "check reduce");

# check set
$c->iter(sub($x, $y, $value) {
    $c->set($x,$y, 1);
});
my $field_amount = $c->reduce(0, sub($acc, $value, $x, $y) { $acc + $value });
is($field_amount, $c->width * $c->height, "check iter/set");

# check show
my $str = $c->show(sub ($x, $y, $value) { $value });
is($str, "11111\n" x 5, "check show");

# check is_inside
is($c->is_inside(0,0),       1, "is inside");
is($c->is_inside(10,10), undef, "not inside");

done_testing;