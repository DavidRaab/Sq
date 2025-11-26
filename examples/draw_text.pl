#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

sub create_canvas($width, $height, $default=" ") {
    return sq {
        width  => $width,
        height => $height,
        data   => [($default) x ($width * $height)],
    };
}

# data is a single array that emulates a 2D Array, so $x,$y must be converted
# into an offset. Position outside canvas are ignored
sub setChar($canvas, $x,$y, $char) {
    my ($cw,$ch,$data) = $canvas->@{qw/width height data/};
    return if $x < 0 || $x >= $cw;
    return if $y < 0 || $y >= $ch;
    my $offset = ($y * $ch) + $x;
    $data->[$offset] = $char;
    return;
}

# this iterates a $canvas
sub iter($canvas, $f) {
    my ($cw, $ch, $data) = $canvas->@{qw/width height data/};

    my $idx = 0;
    for my $x ( 0 .. ($cw-1) ) {
        for my $y ( 0 .. ($ch-1) ) {
            $f->($x,$y,$data->[$idx++]);
        }
    }
    return;
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

# completely fills a canvas with a character
sub fill($canvas, $char) {
    my $data = $canvas->{data};
    for my $x ( @$data ) {
        $x = $char;
    }
    return;
}

# inserts $other_canvas into $canvas at position $x,$y
sub insert($canvas, $x,$y, $other_canvas) {
    my ($w,$h,$data) = $canvas->@{qw/width height data/};
    my $oc           = $other_canvas;

    # when x,y is outside canvas (right,bottom) immediately abort
    return if $x > $w && $y > $h;
    # when x,y is too far top/left outside canvas without that anything
    # clips into $canvas, also abort.
    return if ($x + $oc->{width})  < 0;
    return if ($y + $oc->{height}) < 0;

    iter($other_canvas, sub($ox,$oy,$char) {
        setChar($canvas, ($x+$ox), ($y+$oy), $char);
    });

    return;
}

# creates string out of $canvas
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


### Tests

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
is(
    to_string($canvas),
    "Tefghijkl \n".
    "aa        \n".
    "          \n".
    "   xxxxxxx\n".
    "TTTTTTTTTT\n".
    "          \n".
    "          \n".
    "          \n".
    "          \n".
    "          \n",
    'canvas 1');

# show_canvas($canvas);

fill($canvas, 'a');
is(
    to_string($canvas),
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n",
    'canvas 2');

setChar($canvas, 0,0, 'b');
setChar($canvas, 9,0, 'b');
setChar($canvas, 0,9, 'b');
setChar($canvas, 9,9, 'b');
is(
    to_string($canvas),
    "baaaaaaaab\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "baaaaaaaab\n",
    'canvas 3');

setChar($canvas, -1,0, 'c');
setChar($canvas, 10,0, 'c');
setChar($canvas, 5,-1, 'c');
setChar($canvas, 5,10, 'c');

is(
    to_string($canvas),
    "baaaaaaaab\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "baaaaaaaab\n",
    'canvas 4');

my $box = create_canvas(4,4, "X");
insert($canvas, 3,3, $box);

is(
    to_string($canvas),
    "baaaaaaaab\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "aaaXXXXaaa\n".
    "aaaXXXXaaa\n".
    "aaaXXXXaaa\n".
    "aaaXXXXaaa\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "baaaaaaaab\n",
    'canvas 5');
