#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

sub create_canvas($width, $height, $default=" ") {
    return {
        width  => $width,
        height => $height,
        data   => [($default) x ($width * $height)],
    };
}

# writes $str into $x,$y position in $canvas, does clipping by default
sub cwrite($canvas, $x,$y, $str) {
    my ($cw,$ch,$data) = $canvas->@{qw/width height data/};
    my $skip           = $x < 0 ? abs($x) : 0;
    $x                 = $x < 0 ? 0 : $x;
    my $start          = ($ch * $y) + $x;
    my $max_stop       = ($ch * ($y+1)) - 1;
    my $needed_stop    = ($ch * $y) + $x + (length($str) - $skip - 1);
    my $stop           = $max_stop < $needed_stop ? $max_stop : $needed_stop;

    my @str = split //, $str;
    my $idx = 0;
    for my $offset ( $start .. $stop ) {
        $data->[$offset] = $str[$skip + $idx++];
    }

    return;
}

sub to_string($canvas) {
    my ($cw,$ch,$data) = $canvas->@{qw/width height data/};

    my $str;
    for my $y ( 0 .. ($ch-1) ) {
        for my $x ( 0 .. ($cw-1) ) {
            $str .= $data->[$ch * $y + $x];
        }
        $str .= "\n";
    }
    return $str;
}

sub show_canvas($canvas) {
    print to_string($canvas);
}


my $canvas = create_canvas(10,10);
cwrite($canvas, 0,0, "a");
cwrite($canvas, 1,0, "a");
cwrite($canvas, 2,0, "a");

cwrite($canvas, 0,1, "a");
cwrite($canvas, 1,1, "a");
cwrite($canvas, 1,1, "a");

cwrite($canvas,  3,3, "xxxxxxxxxxxxxx");
cwrite($canvas, -3,0, "abcdefghijkl");
cwrite($canvas, -3,0, "TTTT");
cwrite($canvas, -3,4, "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT");
show_canvas($canvas);