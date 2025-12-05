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
    return hash(
        width       => $width,
        height      => $height,
        default     => $default,
        offset      => array(0,0),
        pos         => array(0,0),
        tab_spacing => 4,
        data        => Array->init($height, ($default x $width)),
    );
}

sub setPos($canvas, $x,$y) {
    $canvas->{pos}[0] = $x;
    $canvas->{pos}[1] = $y;
    return;
}

sub set_spacing($canvas, $count) {
    $canvas->{tab_spacing} = $count;
    return;
}

# setChar() does clipping by default. Positions outside canvas are not
# drawn. Offset still must be applied. \r and \n are handled like
# expected and have an effect even when outside canvas.
sub setChar($canvas, $x,$y, $str) {
    my ($w,$h,$data,$ht,$def) = $canvas->@{qw/width height data tab_spacing default/};
    my ($ox,$oy)              = $canvas->{offset}->@*;
    my ($rx,$ry)              = ($ox+$x, $oy+$y);

    return if $ry >= $h;
    my $ord  = 0;
    my $line = $data->[$ry];
    for my $char ( split //, $str ) {
        $ord = ord $char;
        # when special character
        if ( $ord < 32 ) {
            # newline
            if ( $ord == 10 ) {
                $data->[$ry] = $line;
                $rx = $ox;
                return if ++$ry >= $h;
                $line = $data->[$ry];
            }
            # horizontal tab
            elsif ( $ord == 9 ) {
                for ( 1 .. $ht ) {
                    $rx++, next if $rx < 0 || $rx >= $w;
                    $rx++, next if $ry < 0;
                    substr($line, $rx, 1, $def);
                    $rx++;
                }
            }
            # \r
            elsif ( $ord == 13 ) { $rx = $ox }
            # backspace
            elsif ( $ord == 8  ) { $rx--     }
            # vertical tab
            elsif ( $ord == 11 ) {
                $data->[$ry] = $line;
                return if ++$ry >= $h;
                $line = $data->[$ry];
            }
            else {
                $rx++;
            }
        }
        # any other character
        else {
            $rx++, next if $rx < 0 || $rx >= $w;
            $rx++, next if $ry < 0;
            substr($line, $rx, 1, $char);
            $rx++;
        }
    }
    $data->[$ry] = $line;
    return;
}

sub put($canvas, $str) {
    my ($data,$pos,$w,$h,$def,$ht) = $canvas->@{qw/data pos width height default tab_spacing/};
    my ($ox,$oy)                   = $canvas->{offset}->@*;
    my ($x,$y)                     = @$pos;

    # when setPos was set far outside canvas height, then we need to create lines
    while ( $y+$oy >= $h ) {
        $h++;
        $canvas->{height}++;
        push @$data, ($def x $w);
    }

    my $ord    = 0;
    my $line   = $data->[$y+$oy];
    for my $char ( split //, $str ) {
        # when position is outside canvas width. Then we must go to next line.
        # Maybe add another new line when height is exceeded.
        if ( $ox+$x >= $w ) {
            $data->[$y+$oy] = $line;
            $x = 0;
            $y++;
            if ( $y+$oy >= $h ) {
                $h++;
                $canvas->{height}++;
                push @$data, ($def x $w);
            }
            $line = $data->[$y+$oy];
        }

        $ord = ord $char;
        if ( $ord < 32 ) {
            # newline
            if ( $ord == 10 ) {
                $data->[$y+$oy] = $line;
                $x = 0;
                $y++;
                if ( $y+$oy >= $h ) {
                    $h++;
                    $canvas->{height}++;
                    push @$data, ($def x $w);
                }
                $line = $data->[$y+$oy];
            }
            # horizontal tab
            elsif ( $ord == 9 ) {
                # save everything done so far
                $data->[$y+$oy] = $line;
                $pos->[0]       = $x;
                $pos->[1]       = $y;

                # do recursive call
                put($canvas, $def x $ht);

                # update current state
                $h      = $canvas->{height};
                ($x,$y) = $canvas->{pos}->@*;
                $line   = $data  ->[$y+$oy];
            }
            # \r
            elsif ( $ord == 13 ) {
                $x = 0
            }
            # backspace
            elsif ( $ord == 8 ) {
                $x = $x > 0 ? $x-1 : 0;
            }
            # vertical tab
            elsif ( $ord == 11 ) {
                $data->[$y+$oy] = $line;
                $y++;
                if ( $y+$oy >= $h ) {
                    $h++;
                    $canvas->{height}++;
                    push @$data, ($def x $w);
                }
                $line = $data->[$y+$oy];
            }
            # other special character
            else {
                $x++;
            }
        }
        # any other char
        else {
            substr $line, ($ox+$x), 1, $char;
            $x++;
        }
    }
    $data->[$y+$oy] = $line;
    $pos ->[0]      = $x;
    $pos ->[1]      = $y;
    return;
}

sub add_line($canvas) {
    $canvas->{height}++;
    push $canvas->{data}->@*, ($canvas->{default} x $canvas->{width});
    return;
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
    return substr $data->[$ry], $rx, 1;
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
        setChar($canvas, $x-$ox,$y+$row-$oy, $src->[$row]);
    }
    return;
}

sub iter($canvas, $f) {
    my ($data)   = $canvas->{data};
    my ($ox,$oy) = $canvas->{offset}->@*;

    my ($x,$y) = (0,0);
    for my $line ( @$data ) {
        for my $char ( split //, $line ) {
            $f->($x-$ox, $y-$oy, $char);
            $x++;
        }
        $y++;
        $x=0;
    }
    return;
}

sub iterLine($canvas, $f) {
    my ($data,$h) = $canvas->@{qw/data height/};
    my ($ox,$oy)  = $canvas->{offset}->@*;

    for my $y ( 0 .. ($h-1) ) {
        $f->(-$ox,$y-$oy, $data->[$y]);
    }
    return;
}

sub cmap($canvas, $f) {
    my ($data)   = $canvas->{data};
    my ($ox,$oy) = $canvas->{offset}->@*;

    my @new;
    my ($x,$y) = (0,0);
    for my $line ( @$data ) {
        my $new = "";
        for my $char ( split //, $line ) {
            $new .= $f->($x-$ox, $y-$oy, $char);
            $x++;
        }
        push @new, $new;
        $y++;
        $x=0;
    }
    $canvas->{data} = bless(\@new, 'Array');
    return;
}

sub fill($canvas, $char) {
    my ($w,$h) = $canvas->@{qw/width height/};
    $canvas->{data} = Array->init($h, ($char x $w));
    return;
}

# creates string out of $canvas
sub to_string($canvas) {
    my ($cw, $data) = $canvas->@{qw/width data/};
    return join("\n", @$data). "\n";
}

# creates array of string from $canvas. Optimal to use in other
# functions like Sq->fs->write_text or Sq->fmt->table or just
# for testing
sub to_array($canvas) {
    return $canvas->{data};
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
    state $div = Sq->math->divide_spread;

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
        data   => ["12345",".....","....."],
        height => 3,
        width  => 5
    }),
    "12345\n".
    ".....\n".
    ".....\n",
    'to_string 1');

is(
    to_string({
        data   => [".1234","5....","....."],
        height => 3,
        width  => 5
    }),
    ".1234\n".
    "5....\n".
    ".....\n",
    'to_string 2');

# add_line
{
    my $canvas = create_canvas(5,3,'.');
    is(to_array($canvas), [
        ".....",
        ".....",
        ".....",
    ], 'to_array');

    add_line($canvas);

    is(to_array($canvas), [
        ".....",
        ".....",
        ".....",
        ".....",
    ], 'add_line');
}

# put
{
    my $canvas = create_canvas(4,3,'.');

    put($canvas, 'X');
    is(
        to_string($canvas),
        "X...\n".
        "....\n".
        "....\n",
        "put 1");

    put($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        "....\n".
        "....\n",
        "put 2");

    setPos($canvas, 1,1);
    put($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        ".X..\n".
        "....\n",
        "put 3");

    put($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        ".XX.\n".
        "....\n",
        "put 4");

    put($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        ".XXX\n".
        "....\n",
        "put 5");

    put($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        ".XXX\n".
        "X...\n",
        "put 6");

    put($canvas, 'XXX');
    is(
        to_string($canvas),
        "XX..\n".
        ".XXX\n".
        "XXXX\n",
        "put 7");

    put($canvas, 'AAA');
    is(
        to_string($canvas),
        "XX..\n".
        ".XXX\n".
        "XXXX\n".
        "AAA.\n",
        "put 8");

    put($canvas, 'Whatever');
    is(
        to_string($canvas),
        "XX..\n".
        ".XXX\n".
        "XXXX\n".
        "AAAW\n".
        "hate\n".
        "ver.\n",
        "put 9");
}

# put + setPos
{
    my $canvas = create_canvas(5,3,'.');
    addOffset($canvas, 1,1);
    put($canvas, 'XXXXXX');

    is(
        to_string($canvas),
        ".....\n".
        ".XXXX\n".
        ".XX..\n",
        'put with offset');

    fill($canvas, '.');
    setPos($canvas, 3,1);
    put($canvas, "AAAA");

    is(
        to_string($canvas),
        ".....\n".
        ".....\n".
        "....A\n".
        ".AAA.\n",
        'setPos with offset');
}

# put() supports "\r" and "\n"
{
    my $canvas = create_canvas(5,3,'.');
    addOffset($canvas, 1,1);

    put($canvas, "abc");
    is(to_array($canvas), [
        '.....',
        '.abc.',
        '.....',
    ], 'put ext 1');

    # with this test i found another bug. Even if it didn't
    # test \r or \n. So this test should not be deleted.
    put($canvas, "de");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.e...',
    ], 'put ext 2');

    put($canvas, "fg");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.efg.',
    ], 'put ext 3');

    put($canvas, "\rh");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
    ], 'put - check \r');

    put($canvas, "\nij");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
    ], 'put - check \n');

    put($canvas, "\t1");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
    ], 'put - check \t 1');

    put($canvas, "\t1");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
        '....1',
    ], 'put - check \t 2');

    set_spacing($canvas, 2);
    put($canvas, "\t1\t2\t3");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
        '....1',
        '...1.',
        '..2..',
        '.3...',
    ], 'put - set_spacing and \t');

    put($canvas, "\b4");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
        '....1',
        '...1.',
        '..2..',
        '.4...',
    ], 'put - backspace 1');

    put($canvas, "\b5");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
        '....1',
        '...1.',
        '..2..',
        '.5...',
    ], 'put - backspace 2');

    put($canvas, "\b\b\b0");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
        '....1',
        '...1.',
        '..2..',
        '.0...',
    ], 'put - backspace 3');

    put($canvas, "12\x0b34");
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
        '....1',
        '...1.',
        '..2..',
        '.012.',
        '....3',
        '.4...',
    ], 'put - vertical tab');
}

{
    my $canvas = create_canvas(10,1,'.');
    setPos($canvas, 0,5);
    put($canvas, "1234");
    is(to_array($canvas), [
        '..........',
        '..........',
        '..........',
        '..........',
        '..........',
        '1234......',
    ], 'setPos outside canvas hight, then put');
}

# check if setChar() supports \r and \n
{
    my $canvas = create_canvas(5,3,'.');
    addOffset($canvas, 1,1);

    setChar($canvas, 0,0, "abc");
    is(to_array($canvas), [
        '.....',
        '.abc.',
        '.....',
    ], 'setChar - just fill to start');

    put($canvas, "de");
    is(to_array($canvas), [
        '.....',
        '.dec.',
        '.....',
    ], 'setChar - check if overwrites 1');

    setChar($canvas, 0,0, "abc");
    is(to_array($canvas), [
        '.....',
        '.abc.',
        '.....',
    ], 'setChar - check if overwrites 2');

    setChar($canvas, 0,0, "abc\rd");
    is(to_array($canvas), [
        '.....',
        '.dbc.',
        '.....',
    ], 'setChar - implements \\r');

    setChar($canvas, 0,0, "abc\rd\ne");
    is(to_array($canvas), [
        '.....',
        '.dbc.',
        '.e...',
    ], 'setChar - implements \\n');

    setChar($canvas, 0,0, "abc\rd\nef\nghi");
    is(to_array($canvas), [
        '.....',
        '.dbc.',
        '.ef..',
    ], 'setChar - does not expand height 1');

    setChar($canvas, 0,0, "j\nklm\rn\nop");
    is(to_array($canvas), [
        '.....',
        '.jbc.',
        '.nlm.',
    ], 'setChar - does not expand height 2');

    setChar($canvas, 0,0, "111111\r22");
    is(to_array($canvas), [
        '.....',
        '.2211',
        '.nlm.',
    ], 'setChar - \\r outside width');

    setChar($canvas, 0,0, "33333\r2222222\n3");
    is(to_array($canvas), [
        '.....',
        '.2222',
        '.3lm.',
    ], 'setChar - \\n outside width');
}

# \r and \n with negative offsets
{
    my $canvas = create_canvas(5,3,'.');
    addOffset($canvas, -1,-1);

    setChar($canvas, 0,0, "11111");
    is(to_array($canvas), [
        '.....',
        '.....',
        '.....',
    ], 'setChar - write outside canvas');

    setChar($canvas, 0,0, "\n12345");
    is(to_array($canvas), [
        '2345.',
        '.....',
        '.....',
    ], 'setChar - negative offset with \\n');

    setChar($canvas, 0,0, "\n12345\r67");
    is(to_array($canvas), [
        '7345.',
        '.....',
        '.....',
    ], 'setChar - negative offset with \\n and \\r');

    setChar($canvas, 0,0, "\n12345\r6789\b0");
    is(to_array($canvas), [
        '7805.',
        '.....',
        '.....',
    ], 'setChar - backspace handling');

    setChar($canvas, 0,0, "\n12345\r6789\b0\x0bab");
    is(to_array($canvas), [
        '7805.',
        '...ab',
        '.....',
    ], 'setChar - vertical tab');

    setChar($canvas, 0,0, "\n\t1234");
    is(to_array($canvas), [
        '...12',
        '...ab',
        '.....',
    ], 'setChar - horizontal tab');
}

# spacing
{
    my $canvas = create_canvas(10,3,'.');
    is(to_array($canvas), [
        '..........',
        '..........',
        '..........',
    ], 'spacing 1');

    setChar($canvas, 0,0, "\t1");
    is(to_array($canvas), [
        '....1.....',
        '..........',
        '..........',
    ], 'spacing 2');

    set_spacing($canvas, 2);
    setChar($canvas, 0,0, "\t1");
    is(to_array($canvas), [
        '..1.1.....',
        '..........',
        '..........',
    ], 'spacing 3');

    setChar($canvas, 0,0, "\t1\t1");
    is(to_array($canvas), [
        '..1..1....',
        '..........',
        '..........',
    ], 'spacing 4');

    set_spacing($canvas, -5);
    setChar($canvas, 0,0, "\t1\t1");
    is(to_array($canvas), [
        '111..1....',
        '..........',
        '..........',
    ], 'spacing 5');
}

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