#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

# First i create a mutable implementation. The first implementation just
# provided basic set/get and to_string. Everything else was implemented
# in combinator. But i changed implementation and put more into the
# mutable implementation. This makes some stuff easier and more extendable.
# Combinator API is just a wrapper around the mutable one. This is also
# a little bit faster.

sub create_canvas($width, $height, $default=" ") {
    Carp::croak "width  must be > 0"               if $width  <= 0;
    Carp::croak "height must be > 0"               if $height <= 0;
    Carp::croak "default must be single character" if length($default) != 1;
    return sq {
        width   => $width,
        height  => $height,
        default => $default,
        offset  => [0,0],
        data    => $default x ($width * $height),
    };
}

BEGIN {
    # When this is true. Then $set_easy is used as setChar function.
    # Otherwise $set_complex is used.
    my $easy = 0;

    # This does an "intelligent" computation to only copy those characters
    # from string into $canvas that are visible. So clipping and strings
    # outside canvas should be faster. But this increases the calculation
    # of every setChar() call. Without much clipping it just does more
    # calculation instead of just copying everything.
    my $set_complex = sub($canvas, $x,$y, $str) {
        my ($cw,$ch,$data) = $canvas->@{qw/width height data/};
        my ($ox,$oy)       = $canvas->{offset}->@*;
        $x += $ox;
        $y += $oy;

        # when $x is negative, we must skip characters to print in $str
        # $x is set to zero because that's the virtual position we write
        my $skip        = $x < 0 ? abs($x) : 0;
        $x              = $x < 0 ? 0 : $x;
        # $offset is the offset in $data we need to write
        my $offset      = ($cw * $y) + $x;

        # this is the maximum position of the current line
        my $max_stop    = ($cw * ($y+1));
        # the end offset we need to write. This can be lower than $max_stop
        # when string is shorter than remaining space. Or bigger when
        # $str is much larger than remaining space
        my $needed_stop = ($cw * $y) + $x + (length($str) - $skip);
        # as we clip, we must use the lower $stop
        my $stop        = $max_stop < $needed_stop ? $max_stop : $needed_stop;
        # now calculate real characters we need to write
        my $length      = $stop - $offset;

        # different aborts when nothing is to write, or we are outside canvas
        return if $length < 0 || $y >= $ch || $stop < 0;
        substr($data, $offset, $length, substr($str, $skip, $length));
        $canvas->{data} = $data;
        return;
    };

    # data is a single string that is used like a 2D Array, so $x,$y must
    # be converted into an offset. Position outside canvas are ignored
    my $set_easy = sub($canvas, $x,$y, $str) {
        my ($cw,$ch,$data) = $canvas->@{qw/width height data/};
        my ($ox,$oy)       = $canvas->{offset}->@*;
        my ($rx,$ry)       = ($ox+$x, $oy+$y);

        for my $char ( split //, $str ) {
            $rx++, next if $rx < 0 || $rx >= $cw;
            $rx++, next if $ry < 0 || $ry >= $ch;
            substr $data, ($cw*$ry+$rx), 1, $char;
            $rx++;
        }
        $canvas->{data} = $data;
        return;
    };

    $easy ? fn setChar => $set_easy
          : fn setChar => $set_complex;
}

# TODO
# Writes $str into $canvas but does a word wrap when space is not enough
sub setCharWrap($canvas, $x,$y, $str) {
    my ($cw,$ch,$data) = $canvas->@{qw/width height data/};
    my ($ox,$oy)       = $canvas->{offset}->@*;

    ...
}

sub getChar($canvas, $x,$y) {
    my ($cw,$ch,$data) = $canvas->@{qw/width height data/};
    my ($ox,$oy)       = $canvas->{offset}->@*;
    my ($rx,$ry)       = ($ox+$x, $oy+$y);
    return if $rx < 0 || $rx >= $cw;
    return if $ry < 0 || $ry >= $ch;
    return substr $data, ($cw*$ry+$rx), 1;
}

sub addOffset($canvas, $x,$y) {
    my $offset = $canvas->{offset};
    $offset->[0] += $x;
    $offset->[1] += $y;
    return;
}

sub clearOffset($canvas) {
    my $offset = $canvas->{offset};
    $offset->[0] = 0;
    $offset->[1] = 0;
    return;
}

sub getOffset($canvas) {
    return $canvas->{offset}->@*;
}

# Draws $other canvas into $canvas
sub merge($canvas, $x,$y, $other) {
    my ($src,$w,$h) = $other->@{qw/data width height/};
    my ($ox,$oy)    = $other->{offset}->@*;

    for my $row ( 0 .. ($h-1) ) {
        setChar($canvas, $x-$ox,$y+$row-$oy, substr($src, $row*$w, $w));
    }
    return;
}

sub iter($canvas, $f) {
    my ($data, $w, $h) = $canvas->@{qw/data width height/};
    my ($ox,$oy)       = $canvas->{offset}->@*;

    my ($x,$y) = (0,0);
    for my $char ( split //, $data ) {
        $f->($x-$ox, $y-$oy, $char);
        $x++;
        if ( $x >= $w ) {
            $x = 0;
            $y++;
        }
    }
    return;
}

sub iterLine($canvas, $f) {
    my ($data,$w,$h) = $canvas->@{qw/data width height/};
    my ($ox,$oy)     = $canvas->{offset}->@*;

    for my $y ( 0 .. ($h-1) ) {
        $f->(-$ox,$y-$oy, substr($data, $w*$y, $w) );
        $y++;
    }
    return;
}

sub cmap($canvas, $f) {
    my ($data, $w, $h) = $canvas->@{qw/data width height/};
    my ($ox,$oy)       = $canvas->{offset}->@*;

    my $new = "";
    my ($x,$y) = (0,0);
    for my $char ( split //, $data ) {
        $new .= $f->($x-$ox, $y-$oy, $char);
        $x++;
        if ( $x >= $w ) {
            $x = 0;
            $y++;
        }
    }
    $canvas->{data} = $new;
    return;
}

sub fill($canvas, $char) {
    my ($w,$h)      = $canvas->@{qw/width height/};
    $canvas->{data} = $char x ($w*$h);
    return;
}

# creates string out of $canvas
sub to_string($canvas) {
    my ($cw, $data) = $canvas->@{qw/width data/};
    return $data =~ s/(.{$cw})/$1\n/gr;
}

sub line($canvas, $xs,$ys, $xe,$ye, $char) {
    my $dx  = abs($xe - $xs);
    my $sx  = $xs < $xe ? 1 : -1;
    my $dy  = -abs($ye - $ys);
    my $sy  = $ys < $ye ? 1 : -1;
    my $err = $dx + $dy;
    my $e2; # error value e_xy

    while (1) {
        setChar($canvas, $xs,$ys, $char);
        last if $xs == $xe && $ys == $ye;
        $e2 = 2 * $err;
        if ($e2 > $dy) { $err += $dy; $xs += $sx; }
        if ($e2 < $dx) { $err += $dx; $ys += $sy; }
    }
    return;
}


sub rect($canvas, $tx,$ty, $bx,$by, $char) {
    line($canvas, $tx,$ty, $bx,$ty, $char); # top
    line($canvas, $tx,$ty, $tx,$by, $char); # left
    line($canvas, $bx,$ty, $bx,$by, $char); # right
    line($canvas, $tx,$by, $bx,$by, $char); # bottom
    return;
}

sub vsplit($canvas, @draws) {
    state $div = Sq->math->divide_even_spread;

    my $spaces        = @draws;
    my ($cw,$ch,$def) = $canvas->@{qw/width height default/};
    my $widths        = $div->($cw, $spaces);

    my $offset = 0;
    for (my $idx=0; $idx<@draws; $idx++) {
        my $width = $widths->[$idx];
        my $draw  = $draws[$idx];

        my $new = create_canvas($width, $ch, $def);
        $draw->($new);
        merge($canvas, $offset,0, $new);
        $offset += $width;
    }
    return;
}

sub show_canvas($canvas) {
    print to_string($canvas);
}

### Combinator API
# Build on top of the basic functions

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
        my $y = 0;
        for my $inner ( @$aoa ) {
            setChar($canvas, 0,$y++, join('', @$inner));
        }
        return;
    }
}

# from Array of Strings
sub c_fromArray($array) {
    return sub($canvas) {
        my $y = 0;
        for my $line ( @$array ) {
            setChar($canvas, 0,$y++, $line);
        }
        return;
    }
}

sub c_set($x,$y,$str) {
    return sub($canvas) { setChar($canvas, $x,$y, $str) }
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
        my $new = c_run($width, $height, $default, @draws);
        # than merge new canvas in current one
        merge($canvas, 0,0, $new);
        return;
    }
}

sub c_iter($f) {
    return sub($canvas) { iter($canvas, $f) }
}

sub c_fill($def) {
    return sub($canvas) { fill($canvas, $def) }
}

sub c_line($xs,$ys, $xe,$ye, $char) {
    return sub($canvas) { line($canvas, $xs,$ys, $xe,$ye, $char) }
}

sub c_rect($tx,$ty, $bx,$by, $char) {
    return sub($canvas) { rect($canvas, $tx,$ty, $bx,$by, $char) }
}

# vertically splits space into same amounts
sub c_vsplit(@draws) {
    my $spaces = @draws;
    Carp::croak "vsplit: Needs at least one drawing operation" if $spaces == 0;
    return sub($canvas) { vsplit($canvas, @draws) }
}

### Tests

is(
    to_string({
        data   => "12345..........",
        height => 3,
        width  => 5
    }),
    "12345\n".
    ".....\n".
    ".....\n",
    'to_string 1');

is(
    to_string({
        data   => ".12345.........",
        height => 3,
        width  => 5
    }),
    ".1234\n".
    "5....\n".
    ".....\n",
    'to_string 2');

# offset testing
{
    my $canvas = create_canvas(10, 2, '.');

    is([getOffset($canvas)], [0,0], 'getOffset');
    addOffset($canvas, 1,1);
    is([getOffset($canvas)], [1,1], 'addOffset 1');
    clearOffset($canvas);
    is([getOffset($canvas)], [0,0], 'clearOffset');
    addOffset($canvas, 1,1);
    addOffset($canvas, 1,1);
    is([getOffset($canvas)], [2,2], 'addOffset 2');
}

# check getChar, also if it correctly handles offset
{
    my $canvas = create_canvas(10, 2, '.');

    setChar($canvas, 0,0, "0123456789");
    setChar($canvas, 0,1, "abcdefghij");

    is(getChar($canvas, 0,0), '0', 'getChar 1');
    is(getChar($canvas, 5,0), '5', 'getChar 2');
    is(getChar($canvas, 9,0), '9', 'getChar 3');
    is(getChar($canvas, 0,1), 'a', 'getChar 4');
    is(getChar($canvas, 5,1), 'f', 'getChar 5');
    is(getChar($canvas, 9,1), 'j', 'getChar 6');

    addOffset($canvas, 1,1);

    is(getChar($canvas, 0,0),   'b', 'getChar 7');
    is(getChar($canvas, 5,0),   'g', 'getChar 8');
    is(getChar($canvas, 8,0),   'j', 'getChar 9');
    is(getChar($canvas, 0,1), undef, 'getChar 10');
}

# offset with negative writes
{
    my $canvas = create_canvas(3,3,'.');
    addOffset($canvas, 1,1);
    setChar($canvas, -1,-1, 'X');
    is(
        to_string($canvas), "X..\n...\n...\n",
        'setChar still writes in negative offset when inside canvas');
}

# check iter(), also if it correctly handles offset
{
    my $canvas = create_canvas(3,3,'.');
    addOffset($canvas, 1,1);
    my @iters;
    iter($canvas, sub { push @iters, [@_] });
    is(
        \@iters,
        [
            [-1, -1, "."], [0, -1, "." ], [1, -1, "." ],
            [-1,  0, "."], [0,  0, "." ], [1,  0, "." ],
            [-1,  1, "."], [0,  1, "." ], [1,  1, "." ],
        ],
        'iter after offset');
}

# check iterLine
{
    my $canvas = create_canvas(3,3,'.');
    addOffset($canvas, 1,1);

    my @sizes;
    iterLine($canvas, sub { push @sizes, [@_] });
    is(
        \@sizes,
        [
            [-1, -1, "..."],
            [-1,  0, "..."],
            [-1,  1, "..."],
        ],
        'iterLine with offset');
}

# check map(), also if it correctly handles offset
{
    my $canvas = create_canvas(3,3,'.');
    setChar($canvas, 0,0, "012");
    setChar($canvas, 0,1, "345");
    setChar($canvas, 0,2, "678");
    addOffset($canvas, 1,1);

    my @iters;
    cmap($canvas, sub($x,$y,$char) {
        push @iters, [$x,$y];
        return $char + 1;
    });
    is(
        \@iters,
        [
            [-1, -1], [0, -1], [1, -1],
            [-1,  0], [0,  0], [1,  0],
            [-1,  1], [0,  1], [1,  1],
        ],
        'map handles offset');

    is(to_string($canvas), "123\n456\n789\n", 'string after canvas');
}

# check merge, and how it handles offsets
{
    my $first  = create_canvas(5,5,'.');
    my $second = create_canvas(3,3,'x');

    merge($first, 0,0, $second);
    is(to_string($first), "xxx..\nxxx..\nxxx..\n.....\n.....\n", "merge 1");

    fill($first, '.');
    addOffset($first, 1,1);
    merge($first, 0,0, $second);
    is(to_string($first), ".....\n.xxx.\n.xxx.\n.xxx.\n.....\n", "merge 2");

    fill($first, '.');
    clearOffset($first);
    addOffset($second, 1,1);
    merge($first, 0,0, $second);
    is(to_string($first), "xx...\nxx...\n.....\n.....\n.....\n", "merge 3");

    fill($first, '.');
    clearOffset($first);
    clearOffset($second);
    addOffset($first,2,2);
    addOffset($second,1,1);
    merge($first, 0,0, $second);
    is(to_string($first), ".....\n.xxx.\n.xxx.\n.xxx.\n.....\n", "merge 4");
}

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
    c_string(8,3,".", c_set(2,1,"12345")),
    "........\n".
    "..12345.\n".
    "........\n",
    'c_set 4');

is(
    c_string(8,3,".",
        c_fill('o'),
        c_set(0,2,"12345")),
    "oooooooo\n".
    "oooooooo\n".
    "12345ooo\n",
    'c_fill 1');

is(
    c_string(10,6,'.',
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
    "Tefghijkl.\n".
    "aa........\n".
    "..........\n".
    "...xxxxxxx\n".
    "TTTTTTTTTT\n".
    "..........\n",
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

is(
    c_string(20,3,'.', c_vsplit(
        c_set(0,0,"Hello"),
        c_set(0,0,"World"),
    )),
    "Hello.....World.....\n".
    "....................\n".
    "....................\n",
    'vsplit 1');

is(
    c_string(20,3,'.', c_vsplit(
        c_set(0,0,"x"),
        c_set(0,0,"x"),
        c_set(0,0,"x"),
        c_set(0,0,"x"),
    )),
    "x....x....x....x....\n".
    "....................\n".
    "....................\n",
    'vsplit 2');

is(
    c_string(20,3,'.', c_vsplit(
        c_set(0,0,"aaaaaaaaaaaa"),
        c_set(0,0,"bbbbbbbbbbbb"),
        c_set(0,0,"cccccccccccc"),
        c_set(0,0,"dddddddddddd"),
    )),
    "aaaaabbbbbcccccddddd\n".
    "....................\n".
    "....................\n",
    'vsplit 3');

is(
    c_string(19,3,'.', c_vsplit(
        c_set(0,0,"aaaaaaaaaaaa"),
        c_set(0,0,"bbbbbbbbbbbb"),
        c_set(0,0,"cccccccccccc"),
        c_set(0,0,"dddddddddddd"),
    )),
    "aaaabbbbbcccccddddd\n".
    "...................\n".
    "...................\n",
    'vsplit 4');

is(
    c_string(19,3,'.', c_vsplit(
        c_vsplit(
            c_set(0,0,"aaaaaaaaaaaa"),
            c_set(0,0,"bbbbbbbbbbbb"),
        ),
        c_vsplit(
            c_set(0,0,"cccccccccccc"),
            c_set(0,0,"dddddddddddd"),
        )
    )),
    "aaaabbbbbcccccddddd\n".
    "...................\n".
    "...................\n",
    'vsplit 5');

is(
    c_string(19,3,'.', c_vsplit(
        c_vsplit(
            c_set(0,0,"aaaaaaaaaaaa"),
            c_set(0,0,"bbbbbbbbbbbb"),
        ),
        c_set(0,0,"cccccccccccc"),
    )),
    "aaaabbbbbcccccccccc\n".
    "...................\n".
    "...................\n",
    'vsplit 6');

done_testing;