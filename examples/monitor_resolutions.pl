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
# diagonals of monitor in inch
my $diagonals = array(24..45);

# print real sizes of monitors
Sq->fmt->table({
    header => ["Aspect Ratio", "Diagonal (inch)", "Width x Height (cm)"],
    data   => Array::cartesian($aspects, $diagonals)->map(sub($args) {
        my ($aspect, $diag) = @$args;
        my ($aratio)        = $aspect->[0] / $aspect->[1];

        my $height = $diag / (sqrt($aratio ** 2 + 1)) * 2.54;
        my $width  = $height * $aratio;

        return [$aspect->join(':'), sprintf('%2d"', $diag), sprintf("%6.2f x %.2f cm", $width, $height)];
    }),
    border => 0,
});

say "";

# print resolution of aspect ratio
Sq->fmt->table({
    header => [qw/Resolution Aspect MPixel/],
    data   => Array::cartesian($heights,$aspects)->map(sub($tuple) {
        my ($height, $aspect) = @$tuple;
        my ($ax,$ay)          = @$aspect;

        my $width = ($height / $ay) * $ax;
        return ["$width x $height", $aspect->join(':'), ($width * $height / 1_000_000)];
    }),
    border => 0,
});