#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

sub create_canvas($width, $height, $default=" ") {
    Carp::croak "width  must be > 0" if $width  <= 0;
    Carp::croak "height must be > 0" if $height <= 0;
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
    $data->[$cw * $y + $x] = $char;
    return;
}

sub getChar($canvas, $x,$y) {
    my ($cw,$ch,$data) = $canvas->@{qw/width height data/};
    return if $x < 0 || $x >= $cw;
    return if $y < 0 || $y >= $ch;
    return $data->[$cw * $y + $x];
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

# inserts $other_canvas into $canvas at position $x,$y -- does clipping
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
            $str .= $data->[$cw * $y + $x];
        }
        $str .= "\n";
    }
    return $str;
}

sub show_canvas($canvas) {
    print to_string($canvas);
}

### Combinator API

sub c_run($width, $height, $default, @draws) {
    my $canvas  = create_canvas($width, $height, $default);
    my $setChar = sub($x,$y,$char) { setChar($canvas, $x,$y, $char) };
    my $getChar = sub($x,$y)       { getChar($canvas, $x,$y)        };
    for my $draw ( @draws ) {
        $draw->($setChar,$getChar,$width,$height);
    }
    return $canvas;
}

# from Array of Array
sub c_fromAoA($aoa) {
    return sub($set,$get,$w,$h) {
        Array::iter2d($aoa, sub($char, $x,$y) {
            $set->($x,$y,$char);
        });
        return;
    }
}

# from Array of Strings
sub c_fromArray($array) {
    return sub($set,$get,$w,$h) {
        my $y = 0;
        for my $line ( @$array ) {
            my $x = 0;
            for my $char ( split //, $line ) {
                $set->($x++, $y, $char);
            }
            $y++;
        }
        return;
    }
}

sub c_char($x,$y,$char) {
    Carp::croak "c_char: must be a single char." if length($char) != 1;
    return sub($set,$get,$w,$h) {
        $set->($x,$y,$char);
        return;
    }
}

sub c_str($x,$y,$str) {
    return sub($set,$get,$w,$h) {
        my $idx = 0;
        for my $char ( split //, $str ) {
            $set->(($x+$idx++), $y, $char);
        }
        return;
    }
}

sub c_and(@draws) {
    return sub($set,$get,$w,$h) {
        for my $draw ( @draws ) {
            $draw->($set,$get,$w,$h);
        }
        return;
    }
}

sub c_offset($ox,$oy, @draws) {
    return sub($set,$get,$w,$h) {
        my $newSet = sub($x,$y,$char) {
            $set->($ox+$x, $oy+$y, $char);
            return;
        };
        my $newGet = sub($x,$y) {
            return $get->($ox+$x, $oy+$y);
        };
        for my $draw ( @draws ) {
            $draw->($newSet, $newGet, $w, $h);
        }
        return;
    }
}

# creates a new canvas. So all @draw commands write into a new canvas. Then
# this canvas is merged into current one. Maybe the merging should be done
# explicitly, so more advanced effects are possible. Currently it is nearly
# the same as calling c_offset(). But here you can set another background.
sub c_canvas($width, $height, $default, @draws) {
    return sub($setChar,$getChar,$w,$h) {
        my $canvas = create_canvas($width, $height, $default);
        my $set    = sub($x,$y,$char) { setChar($canvas, $x,$y, $char) };
        my $get    = sub($x,$y)       { getChar($canvas, $x,$y)        };
        for my $draw ( @draws ) {
            $draw->($set,$get,$width,$height);
        }
        iter($canvas, sub($x,$y,$char) {
            $setChar->($x,$y,$char);
        });
        return;
    }
}

sub c_iter($f) {
    return sub($set,$get,$w,$h) {
        for my $y ( 0 .. ($h-1) ) {
            for my $x ( 0 .. ($w-1) ) {
                $set->($x,$y, $f->($x,$y,$get->($x,$y)));
            }
        }
        return;
    }
}

sub c_fill($def) {
    c_iter(sub($x,$y,$char) { $def });
}


### Tests

is(
    to_string({
        data   => [1,2,3,4,5,".",".",".",".",".",".",".",".",".","."],
        height => 3,
        width  => 5
    }),
    "12345\n".
    ".....\n".
    ".....\n",
    'to_string 1');

is(
    to_string({
        data   => [".",1,2,3,4,5,".",".",".",".",".",".",".",".","."],
        height => 3,
        width  => 5
    }),
    ".1234\n".
    "5....\n".
    ".....\n",
    'to_string 2');

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

insert($canvas,  3,-3, $box); # top
insert($canvas, -3, 3, $box); # left
insert($canvas,  9, 3, $box); # right
insert($canvas,  3, 9, $box); # bottom

is(
    to_string($canvas),
    "baaXXXXaab\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "XaaXXXXaaX\n".
    "XaaXXXXaaX\n".
    "XaaXXXXaaX\n".
    "XaaXXXXaaX\n".
    "aaaaaaaaaa\n".
    "aaaaaaaaaa\n".
    "baaXXXXaab\n",
    'canvas 6');

my $cbox =
    c_and(
        c_char(0,0,'a'),
        c_char(3,0,'a'),
        c_char(0,3,'a'),
        c_char(3,3,'a'));

is(
    to_string(c_run(4,4," ",$cbox)),
    "a  a\n".
    "    \n".
    "    \n".
    "a  a\n",
    'combinator 1');

is(
    to_string(c_run(4,4,".",$cbox)),
    "a..a\n".
    "....\n".
    "....\n".
    "a..a\n",
    'combinator 2');

is(
    to_string(c_run(6,6,".",$cbox)),
    "a..a..\n".
    "......\n".
    "......\n".
    "a..a..\n".
    "......\n".
    "......\n",
    'combinator 3');

is(
    to_string(c_run(8,6,".", c_offset(2,2,$cbox))),
    "........\n".
    "........\n".
    "..a..a..\n".
    "........\n".
    "........\n".
    "..a..a..\n",
    'combinator 4');

{
    my $box =
        c_canvas(3,3, "o",
            c_char(0,0, "X"), c_char(2,0, "X"),
            c_char(0,2, "X"), c_char(2,2, "X"));

    is(
        to_string(
            c_run(9,9,".",
                c_offset(0,0, $box),
                c_offset(6,0, $box),
                c_offset(0,6, $box),
                c_offset(6,6, $box))
        ),
        "XoX...XoX\n".
        "ooo...ooo\n".
        "XoX...XoX\n".
        ".........\n".
        ".........\n".
        ".........\n".
        "XoX...XoX\n".
        "ooo...ooo\n".
        "XoX...XoX\n",
        'c_canvas 1');
}

is(
    to_string(c_run(8,3,".", c_str(0,0,"12345"))),
    "12345...\n".
    "........\n".
    "........\n",
    'c_str 1');

is(
    to_string(c_run(8,3,".", c_str(0,1,"12345"))),
    "........\n".
    "12345...\n".
    "........\n",
    'c_str 2');

is(
    to_string(c_run(8,3,".", c_str(0,2,"12345"))),
    "........\n".
    "........\n".
    "12345...\n",
    'c_str 3');

is(
    to_string(c_run(8,3,".",
        c_fill('o'),
        c_str(0,2,"12345"))),
    "oooooooo\n".
    "oooooooo\n".
    "12345ooo\n",
    'c_str 4');

is(
    to_string(c_run(4,4,".",
        c_fromAoA([
            [qw/o o o o/],
            [qw/o o o o/],
            [qw/o o o o/],
            [qw/o o o o/],
        ]))),
    "oooo\n".
    "oooo\n".
    "oooo\n".
    "oooo\n",
    'c_fromAoA 1');

is(
    to_string(c_run(4,4,".",
        c_fromAoA([
            [qw/o o o o/],
            [qw/o o o o/],
            [qw/o o o o/],
            [qw/o o o o/],
        ]),
        c_char(0,0, 'X'),
        c_char(1,1, 'X'),
        c_char(2,2, 'X'),
        c_char(3,3, 'X'))),
    "Xooo\n".
    "oXoo\n".
    "ooXo\n".
    "oooX\n",
    'c_fromAoA 2');

is(
    to_string(c_run(4,4,".",
        c_fromArray([
            "oooo",
            "oooo",
            "oooo",
            "oooo",
        ]))),
    "oooo\n".
    "oooo\n".
    "oooo\n".
    "oooo\n",
    'c_fromArray 1');

is(
    to_string(
        c_run(4,4,'.',
            c_fromArray([
                "oooo",
                "oooo",
                "oooo",
                "oooo",
            ]),
            c_char(0,0, 'X'),
            c_char(1,1, 'X'),
            c_char(2,2, 'X'),
            c_char(3,3, 'X'))),
    "Xooo\n".
    "oXoo\n".
    "ooXo\n".
    "oooX\n",
    'c_fromArray 2');


is(
    to_string(
        c_run(9,5,".",
            c_offset(0,0,
                c_fromAoA([
                    [qw/o o o o/],
                    [qw/o o o o/],
                    [qw/o o o o/],
                    [qw/o o o o/],
                ]),
                c_char(0,0, 'X'),
                c_char(1,1, 'X'),
                c_char(2,2, 'X'),
                c_char(3,3, 'X')),

            c_offset(5,0,
                c_fromArray([
                    "oooo",
                    "oooo",
                    "oooo",
                    "oooo",
                ]),
                c_char(0,0, 'X'),
                c_char(1,1, 'X'),
                c_char(2,2, 'X'),
                c_char(3,3, 'X')))),
    "Xooo.Xooo\n".
    "oXoo.oXoo\n".
    "ooXo.ooXo\n".
    "oooX.oooX\n".
    ".........\n",
    'c_fromAoA 2');