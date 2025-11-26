#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

# Most basic mutable implementation:
# create_canvas, setChar, getChar, to_string, show_canvas

sub create_canvas($width, $height, $default=" ") {
    Carp::croak "width  must be > 0" if $width  <= 0;
    Carp::croak "height must be > 0" if $height <= 0;
    return sq {
        width  => $width,
        height => $height,
        ox     => 0,       # Offset X
        oy     => 0,       # Offset Y
        data   => [($default) x ($width * $height)],
    };
}

# data is a single array that emulates a 2D Array, so $x,$y must be converted
# into an offset. Position outside canvas are ignored
sub setChar($canvas, $x,$y, $char) {
    my ($cw,$ch,$data,$ox,$oy) = $canvas->@{qw/width height data ox oy/};
    my ($rx,$ry) = ($ox+$x, $oy+$y);
    return if $rx < 0 || $rx >= $cw;
    return if $ry < 0 || $ry >= $ch;
    $data->[$cw * $ry + $rx] = $char;
    return;
}

sub getChar($canvas, $x,$y) {
    my ($cw,$ch,$data,$ox,$oy) = $canvas->@{qw/width height data ox oy/};
    my ($rx,$ry) = ($ox+$x, $oy+$y);
    return if $rx < 0 || $rx >= $cw;
    return if $ry < 0 || $ry >= $ch;
    return $data->[$cw * $ry + $rx];
}

sub addOffset($canvas, $x,$y) {
    $canvas->{ox} = $canvas->{ox} + $x;
    $canvas->{oy} = $canvas->{oy} + $y;
    return;
}

sub iter($canvas, $f) {
    my ($data, $w, $h) = $canvas->@{qw/data width height/};
    for my $y ( 0 .. ($h-1) ) {
        for my $x ( 0 .. ($w-1) ) {
            $f->($x,$y, $data->[$y*$w + $x]);
        }
    }
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
# Build on top of the five basic functions

sub c_run($width, $height, $default, @draws) {
    my $canvas = create_canvas($width, $height, $default);
    for my $draw ( @draws ) {
        $draw->($canvas);
    }
    return $canvas;
}

sub c_string($width, $height, $default, @draws) {
    return to_string(c_run($width, $height, $default, @draws));
}

sub c_and(@draws) {
    return sub($canvas) {
        for my $draw ( @draws ) {
            $draw->($canvas);
        }
        return;
    }
}

# from Array of Array
sub c_fromAoA($aoa) {
    return sub($canvas) {
        Array::iter2d($aoa, sub($char, $x,$y) {
            setChar($canvas, $x,$y, $char);
        });
        return;
    }
}

# from Array of Strings
sub c_fromArray($array) {
    return sub($canvas) {
        my $y = 0;
        for my $line ( @$array ) {
            my $x = 0;
            for my $char ( split //, $line ) {
                setChar($canvas, $x++, $y, $char);
            }
            $y++;
        }
        return;
    }
}

sub c_set($x,$y,$str) {
    return sub($canvas) {
        my $idx = 0;
        for my $char ( split //, $str ) {
            setChar($canvas, ($x+$idx++), $y, $char);
        }
        return;
    }
}

sub c_offset($ox,$oy, @draws) {
    return sub($canvas) {
        addOffset($canvas, $ox,$oy);
        for my $draw ( @draws ) {
            $draw->($canvas);
        }
        addOffset($canvas, -$ox,-$oy);
        return;
    }
}

# creates a new canvas. So all @draw commands write into a new canvas. Then
# this canvas is merged into current one. Maybe the merging should be done
# explicitly, so more advanced effects are possible. Currently it is nearly
# the same as calling c_offset(). But here you can set another background.
sub c_canvas($width, $height, $default, @draws) {
    Carp::croak 'c_canvas($width,$height,$char,@draws)' if ref $default ne "";
    return sub($canvas) {
        # generates a new canvas, and does all drawing operation on it
        my $new  = c_run($width, $height, $default, @draws);
        my $data = $new->{data};

        # than merge new canvas in current one
        my $idx = 0;
        for my $x ( 0 .. ($width-1) ) {
            for my $y ( 0 .. ($height-1) ) {
                setChar($canvas, $x,$y, $data->[$idx++]);
            }
        }

        return;
    }
}

sub c_iter($f) {
    return sub($canvas) {
        iter($canvas, sub($x,$y,$char){
            setChar($canvas, $x,$y, $f->($x,$y,$char));
        });
        return;
    }
}

sub c_fill($def) {
    return sub($canvas) {
        iter($canvas, sub($x,$y,$char){
            setChar($canvas, $x,$y, $def);
        });
    }
}

sub c_line($xs,$ys, $xe,$ye, $char) {
    return sub($canvas) {
        my $dx  = abs($xe - $xs);
        my $sx  = $xs < $xe ? 1 : -1;
        my $dy  = -abs($ye - $ys);
        my $sy  = $ys < $ye ? 1 : -1;
        my $err = $dx + $dy;
        my $e2; # error value e_xy

        while (1) {
            setChar($canvas, $xs, $ys, $char);
            last if $xs == $xe && $ys == $ye;
            $e2 = 2 * $err;
            if ($e2 > $dy) { $err += $dy; $xs += $sx; }
            if ($e2 < $dx) { $err += $dx; $ys += $sy; }
        }
        return;
    }
}

sub c_rect($tx,$ty, $bx,$by, $char) {
    return c_and(
        c_line($tx,$ty, $bx,$ty, $char), # top
        c_line($tx,$ty, $tx,$by, $char), # left
        c_line($bx,$ty, $bx,$by, $char), # right
        c_line($tx,$by, $bx,$by, $char)) # bottom
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

is(
    to_string(c_run(5,5,'.', c_set(3,3,'X') )),
    c_string(5,5,'.',        c_set(3,3,'X') ),
    'c_string is the same as to_string(c_run())');

is(
    c_string(8,3,".", c_set(0,0,"12345")),
    "12345...\n".
    "........\n".
    "........\n",
    'c_set 1');

is(
    c_string(8,3,".", c_set(0,1,"12345")),
    "........\n".
    "12345...\n".
    "........\n",
    'c_set 2');

is(
    c_string(8,3,".", c_set(0,2,"12345")),
    "........\n".
    "........\n".
    "12345...\n",
    'c_set 3');

is(
    c_string(8,3,".",
        c_fill('o'),
        c_set(0,2,"12345")),
    "oooooooo\n".
    "oooooooo\n".
    "12345ooo\n",
    'c_fill 1');

is(
    c_string(10,10,' ',
        c_set( 0,0, "a"),
        c_set( 1,0, "a"),
        c_set( 2,0, "a"),
        c_set( 0,1, "a"),
        c_set( 1,1, "a"),
        c_set( 1,1, "a"),
        c_set( 3,3, "xxxxxxxxxxxxxx"),
        c_set(-3,0, "abcdefghijkl"),
        c_set(-3,0, "TTTT"),
        c_set(-3,4, "TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT"),
    ),
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


my $canvas = c_canvas(20,20,".",c_fill('a'));
is(
    c_string(10,10,'.', $canvas),
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

my $with_corner = c_and($canvas,
    c_set(0,0, 'b'),
    c_set(9,0, 'b'),
    c_set(0,9, 'b'),
    c_set(9,9, 'b'),
);
is(
    c_string(10,10,'.',$with_corner),
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

is(
    c_string(10,10,'.',
        $with_corner,
        c_set(-1,0, 'c'),
        c_set(10,0, 'c'),
        c_set(5,-1, 'c'),
        c_set(5,10, 'c'),
    ),
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

my $box = c_canvas(4,4,'X');
is(
    c_string(10,10,'.',
        $with_corner,
        c_set(-1,0, 'c'),
        c_set(10,0, 'c'),
        c_set(5,-1, 'c'),
        c_set(5,10, 'c'),
        c_offset(3,3, $box),
    ),
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
    'c_offset 1');

is(
    c_string(10,10,'.',
        $with_corner,
        c_set(-1,0, 'c'),
        c_set(10,0, 'c'),
        c_set(5,-1, 'c'),
        c_set(5,10, 'c'),
        c_offset( 3, 3, $box), # middle
        c_offset( 3,-3, $box), # top
        c_offset(-3, 3, $box), # left
        c_offset( 9, 3, $box), # right
        c_offset( 3, 9, $box), # bottom
    ),
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
    'c_offset 2');

my $cbox =
    c_and(
        c_set(0,0,'a'),
        c_set(3,0,'a'),
        c_set(0,3,'a'),
        c_set(3,3,'a'));

is(
    c_string(4,4," ",$cbox),
    "a  a\n".
    "    \n".
    "    \n".
    "a  a\n",
    'c_and 1');

is(
    c_string(4,4,".",$cbox),
    "a..a\n".
    "....\n".
    "....\n".
    "a..a\n",
    'c_and 2');

is(
    c_string(6,6,".",$cbox),
    "a..a..\n".
    "......\n".
    "......\n".
    "a..a..\n".
    "......\n".
    "......\n",
    'c_and 3');

is(
    c_string(8,6,".", c_offset(2,2,$cbox)),
    "........\n".
    "........\n".
    "..a..a..\n".
    "........\n".
    "........\n".
    "..a..a..\n",
    'c_and + c_offset');

{
    my $box =
        c_canvas(3,3, "o",
            c_set(0,0, "X"), c_set(2,0, "X"),
            c_set(0,2, "X"), c_set(2,2, "X"));

    is(
        c_string(9,9,".",
            c_offset(0,0, $box),
            c_offset(6,0, $box),
            c_offset(0,6, $box),
            c_offset(6,6, $box)),
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
    c_string(4,4,".",
        c_fromAoA([
            [qw/o o o o/],
            [qw/o o o o/],
            [qw/o o o o/],
            [qw/o o o o/],
        ])),
    "oooo\n".
    "oooo\n".
    "oooo\n".
    "oooo\n",
    'c_fromAoA 1');

is(
    c_string(4,4,".",
        c_fromAoA([
            [qw/o o o o/],
            [qw/o o o o/],
            [qw/o o o o/],
            [qw/o o o o/],
        ]),
        c_set(0,0, 'X'),
        c_set(1,1, 'X'),
        c_set(2,2, 'X'),
        c_set(3,3, 'X')),
    "Xooo\n".
    "oXoo\n".
    "ooXo\n".
    "oooX\n",
    'c_fromAoA 2');

is(
    c_string(4,4,".",
        c_fromArray([
            "oooo",
            "oooo",
            "oooo",
            "oooo",
        ])),
    "oooo\n".
    "oooo\n".
    "oooo\n".
    "oooo\n",
    'c_fromArray 1');

is(
    c_string(4,4,'.',
        c_fromArray([
            "oooo",
            "oooo",
            "oooo",
            "oooo",
        ]),
        c_set(0,0, 'X'),
        c_set(1,1, 'X'),
        c_set(2,2, 'X'),
        c_set(3,3, 'X')),
    "Xooo\n".
    "oXoo\n".
    "ooXo\n".
    "oooX\n",
    'c_fromArray 2');

is(
    c_string(9,5,".",
        c_offset(0,0,
            c_fromAoA([
                [qw/o o o o/],
                [qw/o o o o/],
                [qw/o o o o/],
                [qw/o o o o/],
            ]),
            c_set(0,0, 'X'),
            c_set(1,1, 'X'),
            c_set(2,2, 'X'),
            c_set(3,3, 'X')),

        c_offset(5,0,
            c_fromArray([
                "oooo",
                "oooo",
                "oooo",
                "oooo",
            ]),
            c_set(0,0, 'X'),
            c_set(1,1, 'X'),
            c_set(2,2, 'X'),
            c_set(3,3, 'X'))),
    "Xooo.Xooo\n".
    "oXoo.oXoo\n".
    "ooXo.ooXo\n".
    "oooX.oooX\n".
    ".........\n",
    'c_fromAoA and c_fromArray');

is(
    c_string(5,5,".", c_line(0,0, 4,4, '+')),
    "+....\n".
    ".+...\n".
    "..+..\n".
    "...+.\n".
    "....+\n",
    'c_line 1');

is(
    c_string(5,5,".", c_line(0,0, 4,0, '+')),
    "+++++\n".
    ".....\n".
    ".....\n".
    ".....\n".
    ".....\n",
    'c_line 2');

is(
    c_string(5,5,".", c_line(0,0, 0,4, '+')),
    "+....\n".
    "+....\n".
    "+....\n".
    "+....\n".
    "+....\n",
    'c_line 3');

is(
    c_string(5,5,".", c_line(0,0, 4,3, '+')),
    "+....\n".
    ".++..\n".
    "...+.\n".
    "....+\n".
    ".....\n",
    'c_line 4');

is(
    c_string(5,5,".", c_line(0,0, 4,2, '+')),
    "++...\n".
    "..++.\n".
    "....+\n".
    ".....\n".
    ".....\n",
    'c_line 5');

is(
    c_string(5,5,".", c_line(0,0, 4,1, '+')),
    "+++..\n".
    "...++\n".
    ".....\n".
    ".....\n".
    ".....\n",
    'c_line 6');

is(
    c_string(5,5,".", c_line(-5,-3, 12,9, '+')),
    ".....\n".
    "++...\n".
    "..+..\n".
    "...++\n".
    ".....\n",
    'c_line 7');

is(
    c_string(5,5,'.', c_rect(0,0, 4,4, '+')),
    c_string(5,5,'.', c_fromArray([
        "+++++",
        "+...+",
        "+...+",
        "+...+",
        "+++++",
    ])),
    'c_rect 1');

is(
    c_string(5,5,".", c_rect(1,1, 3,3, '+')),
    ".....\n".
    ".+++.\n".
    ".+.+.\n".
    ".+++.\n".
    ".....\n",
    'c_rect 2');

done_testing;