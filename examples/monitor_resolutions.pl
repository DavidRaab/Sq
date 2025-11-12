#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

my $heights = array(1080, 1440, 2160);
my $aspects = sq [
    [16,9],
    [21,9],
    [32,9],
];

my $data = Array::cartesian($heights,$aspects)->map(sub($tuple) {
    my ($height, $aspect) = @$tuple;
    my ($ax,$ay)          = @$aspect;

    my $width = ($height / $ay) * $ax;
    array(
        "$width x $height",
        $aspect->join(':'),
        ($width * $height / 1_000_000)
    );
});

Sq->fmt->table({
    header => [qw/Resolution Aspect MPixel/],
    data   => $data,
});