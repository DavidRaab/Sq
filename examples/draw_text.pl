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

sub create_canvas($width, $height, $def=" ") {
    Carp::croak "width  must be > 0"               if $width  <= 0;
    Carp::croak "height must be > 0"               if $height <= 0;
    Carp::croak "default must be single character" if length($def) != 1;
    return hash(
        width       => $width,
        height      => $height,
        default     => $def,
        pos         => [0,0],
        tab_spacing => 4,
        hline       => '─',
        vline       => '│',
        rect        => [
            ['┌', '─',  '┐'],
            ['│', $def, '│'],
            ['└', '─',  '┘'],
        ],
        data => Array->init($height, ($def x $width)),
    );
}

# This creates a canvas where every character is a zero byte. Because
# i handle special characters in set() and put() and most of them are
# just skipped. This acts like a transparent empty image.
sub empty($width, $height) {
    return create_canvas($width, $height, "\x00");
}

###--------------------------
### Basic Canvas operations
###--------------------------

sub make_transparent($canvas) {
    my ($w,$h)      = $canvas->@{qw/width height/};
    $canvas->{data} = Array->init($h, ("\x00" x $w));
    return;
}

sub set_pos($canvas, $x,$y) {
    $canvas->{pos}[0] = $x;
    $canvas->{pos}[1] = $y;
    return;
}

sub set_spacing($canvas, $count) {
    $canvas->{tab_spacing} = $count;
    return;
}

sub clear_canvas($canvas) {
    my ($w,$h,$def) = $canvas->@{qw/width height default/};
    $canvas->{data} = Array->init($h, ($def x $w));
    return;
}

sub add_line($canvas) {
    $canvas->{height}++;
    push $canvas->{data}->@*, ($canvas->{default} x $canvas->{width});
    return;
}

sub get_char($canvas, $x,$y) {
    my ($w,$h,$data) = $canvas->@{qw/width height data/};
    return if $x < 0 || $x >= $w;
    return if $y < 0 || $y >= $h;
    return substr $data->[$y], $x, 1;
}

sub iter($canvas, $f) {
    my ($data) = $canvas->{data};
    my ($x,$y) = (0,0);
    for my $line ( @$data ) {
        for my $char ( split //, $line ) {
            $f->($x,$y, $char);
            $x++;
        }
        $y++;
        $x=0;
    }
    return;
}

sub iter_line($canvas, $f) {
    my ($data,$h) = $canvas->@{qw/data height/};
    for my $y ( 0 .. ($h-1) ) {
        $f->(0,$y, $data->[$y]);
    }
    return;
}

# creates array of string from $canvas. Best to use in other functions
# like Sq->fs->write_text or Sq->fmt->table or just for testing
sub to_array($canvas) {
    my @out = map {
        # removes zero-bytes at end of every line
        my $line = s/\x00++\z//r;
        # also removes whitespace at end of string
        $line =~ s/\s++\z//;
        # replaces zero bytes with whitespace
        $line =~ s/\x00/ /g;
        $line;
    } $canvas->{data}->@*;
    # removes empty lines at end of array
    pop @out while @out && $out[-1] eq "";
    return bless(\@out, 'Array');
}

# creates string out of $canvas
sub to_string($canvas) {
    return join("\n", to_array($canvas)->@*). "\n";
}

sub show_canvas($canvas) {
    print to_string($canvas);
}

# A user is able to manualy set character position. The position can be set
# outside width/height. When this happens position must be updated, maybe
# new lines must be created. This function does all of this handling. But
# it also allows to easily just change position, and after a call to this
# function it does what needs to be done.
sub check_position($canvas) {
    my ($data,$w,$h,$pos,$def) = $canvas->@{qw/data width height pos default/};
    my ($x,$y)                 = $pos->@*;

    # when we are outside max width, then jump to next line
    if ( $x >= $w ) {
        $x = 0;
        $y++;
    }

    # when pos was outside canvas height, then we need to create lines
    while ( $y >= $h ) {
        $h++;
        push @$data, ($def x $w);
    }
    $canvas->{height} = $h;

    $pos->[0] = $x;
    $pos->[1] = $y;
    return;
}

###-----------------------
### Basic Write operations
###-----------------------

sub fill($canvas, $char) {
    my ($w,$h)      = $canvas->@{qw/width height/};
    $canvas->{data} = Array->init($h, ($char x $w));
    return;
}

# set_char() only writes a single character at position and handles offset.
sub set_char($canvas, $x,$y, $char) {
    Carp::croak "set_char only can write single char" if length($char) != 1;
    my ($w,$h,$data) = $canvas->@{qw/width height data/};

    # abort writing when outside canvas
    return if $x < 0 || $x >= $w;
    return if $y < 0 || $y >= $h;

    my $ord = ord $char;
    if ( $ord < 32 ) {
        # allow writing zero byte
        if ( $ord == 0 ) {
            substr($data->[$y], $x, 1, $char);
        }
        # horizontal tab: \t
        elsif ( $ord == 9 ) {
            my $def = $canvas->{default};
            for ( 1 .. $canvas->{tab_spacing} ) {
                return if $x < 0 || $x >= $w;
                substr($data->[$y], $x, 1, $def);
                $x++;
            }
        }
    }
    # all chars >= 32
    else {
        substr($data->[$y], $x, 1, $char);
    }
    return;
}

# put_char() writes a single character to the currently defined position set
# in canvas. check_position() does the position handling and line jumping
# or line adding when needed.
sub put_char($canvas, $char) {
    Carp::croak "put_char only can write a single char" if length($char) != 1;
    check_position($canvas);
    my ($pos)  = $canvas->{pos};
    my ($x,$y) = $pos->@*;

    my $ord = ord $char;
    if ( $ord < 32 ) {
        # zero-byte
        if ( $ord == 0 ) {
            substr $canvas->{data}[$y], $x, 1, $char;
            $pos->[0] = $x + 1;
        }
        # newline
        elsif ( $ord == 10 ) {
            $pos->[0] = 0;
            $pos->[1]++;
        }
        # horizontal tab: \t
        elsif ( $ord == 9 ) {
            my ($def, $ht) = $canvas->@{qw/default tab_spacing/};
            for ( 1 .. $ht ) {
                # replace character and update state
                substr $canvas->{data}[$y], $x, 1, $def;
                $pos->[0] = $x + $ht;
                check_position($canvas);
            }
        }
        # \r
        elsif ( $ord == 13 ) {
            $pos->[0] = 0;
        }
        # backspace
        elsif ( $ord == 8 ) {
            my $x     = $pos->[0];
            $pos->[0] = $x > 0 ? $x-1 : 0;
        }
        # vertical tab
        elsif ( $ord == 11 ) {
            $pos->[1]++;
        }
        # other special character. no write but advance position
        else {
            $pos->[0]++;
        }
    }
    else {
        # replace character and update state
        if ( $x >= 0 && $y >= 0 ) {
            substr $canvas->{data}[$y], $x, 1, $char;
        }
        $pos->[0] = $x + 1;
    }
    return;
}

# set() does clipping by default. Positions outside canvas are not
# drawn. Offset still must be applied. \r and \n are handled like
# expected and have an effect even when outside canvas.
sub set($canvas, $x,$y, $str) {
    my ($w,$h,$data,$ht,$def) = $canvas->@{qw/width height data tab_spacing default/};

    return if $y >= $h;
    my $ord  = 0;
    my $line = $data->[$y];
    for my $char ( split //, $str ) {
        $ord = ord $char;
        # when special character
        if ( $ord < 32 ) {
            # newline
            if ( $ord == 10 ) {
                $data->[$y] = $line;
                $x = 0;
                return if ++$y >= $h;
                $line = $data->[$y];
            }
            # horizontal tab
            elsif ( $ord == 9 ) {
                for ( 1 .. $ht ) {
                    $x++, next if $x < 0 || $x >= $w;
                    $x++, next if $y < 0;
                    substr($line, $x, 1, $def);
                    $x++;
                }
            }
            # \r
            elsif ( $ord == 13 ) { $x = 0 }
            # backspace
            elsif ( $ord == 8  ) {
                $x = $x > 0 ? $x-1 : 0;
            }
            # vertical tab
            elsif ( $ord == 11 ) {
                $data->[$y] = $line;
                return if ++$y >= $h;
                $line = $data->[$y];
            }
            else {
                $x++;
            }
        }
        # any other character
        else {
            $x++, next if $x < 0 || $x >= $w;
            $x++, next if $y < 0;
            substr($line, $x, 1, $char);
            $x++;
        }
    }
    $data->[$y] = $line;
    return;
}

sub put($canvas, $str) {
    my ($pos, $def, $ht) = $canvas->@{qw/pos default tab_spacing/};

    my $ord = 0;
    for my $char ( split //, $str ) {
        $ord = ord $char;
        if ( $ord < 32 ) {
            # newline
            if ( $ord == 10 ) {
                $pos->[0] = 0;
                $pos->[1]++;
            }
            # horizontal tab
            elsif ( $ord == 9 ) {
                for ( 1 .. $ht ) {
                    put_char($canvas, $def);
                }
            }
            # \r
            elsif ( $ord == 13 ) {
                $pos->[0] = 0
            }
            # backspace
            elsif ( $ord == 8 ) {
                my $x     = $pos->[0];
                $pos->[0] = $x > 0 ? $x-1 : 0;
            }
            # vertical tab
            elsif ( $ord == 11 ) {
                $pos->[1]++;
            }
            # other special character
            else {
                $pos->[0]++;
            }
        }
        # any other char
        else {
            put_char($canvas, $char);
        }
    }
    return;
}


###--------------------------
### Extended Canvas operation
###--------------------------

# Writes $str into $canvas but does a word wrap when space is not enough
sub set_wrap($canvas, $x,$y, $str) {
    my $pos      = $canvas->{pos};
    my ($px,$py) = @$pos;
    $pos->[0]    = $x;
    $pos->[1]    = $y;
    put($canvas, $str);
    $pos->[0]    = $px;
    $pos->[1]    = $py;
    return;
}

# places a string into a selection defined by $x,$y and $length
#
# $where = (l)eft, (c)enter, (r)ight
sub place($canvas, $x,$y, $length, $where, $str) {
    my $def = $canvas->{default};

    my $str_length = length $str;
    # Build real string to place
    my $str_to_place;
    # when $str is shorter, then we need to expand string
    if ( $str_length < $length ) {
        if ( $where =~ m/\Al|left\z/i ) {
            my $missing = $length - $str_length;
            $str_to_place = $str . ($def x $missing);
        }
        elsif ( $where =~ m/\Ac|center\z/i ) {
            my $missing = $length - $str_length;
            my $left    = int($missing / 2);
            my $right   = $left;
            $right++ if $missing % 2 == 1;
            $str_to_place = ($def x $left) . $str . ($def x $right);
        }
        # right
        else {
            my $missing = $length - $str_length;
            $str_to_place = ($def x $missing) . $str;
        }
    }
    # otherwise we need to shorten $str
    else {
        if ( $where =~ m/\Al|left\z/i ) {
            $str_to_place = substr($str, 0, $length);
        }
        elsif ( $where =~ m/\Ac|center\z/i ) {
            my $cutaway = $str_length - $length;
            my $left    = int($cutaway / 2);
            my $right   = $left;
            $right++ if $cutaway % 2 == 1;

            $str_to_place = substr($str, 0, ($str_length-$right));
            $str_to_place = substr($str_to_place, $left);
        }
        # right
        else {
            my $offset = $str_length - $length;
            $str_to_place = substr($str, $offset);
        }
    }

    set($canvas, $x,$y, $str_to_place);
    return;
}

# Draws $other canvas into $canvas
sub merge($canvas, $x,$y, $other) {
    my ($src,$h) = $other->@{qw/data height/};
    for my $row ( 0 .. ($h-1) ) {
        set_wrap($canvas, $x,$y+$row, $src->[$row]);
    }
    return;
}

sub clip($canvas, $x,$y, $other) {
    my ($src)    = $other->{data};
    my ($cw,$ch) = $canvas->@{qw/width height/};
    my ($ow,$oh) = $other ->@{qw/width height/};

    my $max_w = $cw - $x;
    my $max_h = $ch - $y;
    my $w     = $ow < $max_w ? $ow : $max_w;
    my $h     = $oh < $max_h ? $oh : $max_h;

    for my $row ( 0 .. ($h-1) ) {
        set($canvas, $x,$y+$row, substr($src->[$row], 0, $w));
    }
    return;
}

sub cmap($canvas, $f) {
    my ($data) = $canvas->{data};

    my @new;
    my ($x,$y) = (0,0);
    for my $line ( @$data ) {
        my $new = "";
        for my $char ( split //, $line ) {
            $new .= $f->($x,$y, $char);
            $x++;
        }
        push @new, $new;
        $y++;
        $x=0;
    }
    $canvas->{data} = bless(\@new, 'Array');
    return;
}

sub line($canvas, $xs,$ys, $xe,$ye, $char) {
    my $dx  = abs($xe - $xs);
    my $sx  = $xs < $xe ? 1 : -1;
    my $dy  = -abs($ye - $ys);
    my $sy  = $ys < $ye ? 1 : -1;
    my $err = $dx + $dy;
    my $e2; # error value e_xy

    while (1) {
        set_char($canvas, $xs,$ys, $char);
        last if $xs == $xe && $ys == $ye;
        $e2 = 2 * $err;
        if ($e2 > $dy) { $err += $dy; $xs += $sx; }
        if ($e2 < $dx) { $err += $dx; $ys += $sy; }
    }
    return;
}

# draws horizontal line
sub hline($canvas, $y, $xs,$xe) {
    my $char = $canvas->{hline};
    for my $x ( $xs .. $xe ) {
        set_char($canvas, $x,$y, $char);
    }
    return;
}

# draws vertical line
sub vline($canvas, $x, $ys,$ye) {
    my $char = $canvas->{vline};
    for my $y ( $ys .. $ye ) {
        set_char($canvas, $x,$y, $char);
    }
    return;
}

# sx,sy -> start
# ex,ey -> end
sub rect($canvas, $sx,$sy, $ex,$ey) {
    my $lx = $sx < $ex ? $sx : $ex;
    my $rx = $sx < $ex ? $ex : $sx;
    my $ty = $sy < $ey ? $sy : $ey;
    my $by = $sy < $ey ? $ey : $sy;

    # top / bottom
    my $rect   = $canvas->{rect};
    my $top    = $rect->[0][1];
    my $bottom = $rect->[2][1];
    for my $x ( $lx .. $rx ) {
        set_char($canvas, $x,$ty, $top);
        set_char($canvas, $x,$by, $bottom);
    }
    # left / right
    my $left  = $rect->[1][0];
    my $right = $rect->[1][2];
    for my $y ( $ty .. $by ) {
        set_char($canvas, $lx,$y, $left);
        set_char($canvas, $rx,$y, $right);
    }

    # corners
    set_char($canvas, $lx,$ty, $rect->[0][0]);
    set_char($canvas, $rx,$ty, $rect->[0][2]);
    set_char($canvas, $lx,$by, $rect->[2][0]);
    set_char($canvas, $rx,$by, $rect->[2][2]);
    return;
}

sub border($canvas) {
    my ($w,$h) = $canvas->@{qw/width height/};
    rect($canvas, 0,0, ($w-1),($h-1));
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


###-----------------------
### Combinator API
###-----------------------

### Runners

sub c_run($width, $height, $default, @draws) {
    my $canvas = create_canvas($width, $height, $default);
    for my $draw ( @draws ) {
        $draw->($canvas);
    }
    return $canvas;
}

sub c_empty($w,$h, @draws) {
    my $canvas = empty($w,$h);
    for my $draw ( @draws ) {
        $draw->($canvas);
    }
    return $canvas;
}

# from Array of Array
sub c_fromAoA($aoa) {
    my ($w,$h) = Array::dimensions2d($aoa);
    my $canvas = empty($w,$h);
    my $y = 0;
    for my $inner ( @$aoa ) {
        set($canvas, 0,$y++, join('', @$inner));
    }
    return $canvas;
}

# from Array of Strings
sub c_fromArray($array) {
    my $h   = @$array;
    my $w   = 0;
    my $len = 0;
    for my $str ( @$array ) {
        $len = length($str);
        $w   = $len > $w ? $len : $w;
    }

    my $canvas = empty($w,$h);
    my $y = 0;
    for my $line ( @$array ) {
        set($canvas, 0,$y++, $line);
    }
    return $canvas;
}

sub c_string($width, $height, $default, @draws) {
    return to_string(c_run($width, $height, $default, @draws));
}

### Combinators

sub c_make_transparent() {
    return sub($canvas) {
        make_transparent($canvas);
        return;
    }
}

sub c_and(@draws) {
    return sub($canvas) {
        for my $draw ( @draws ) {
            $draw->($canvas);
        }
        return;
    }
}

sub c_set($x,$y,$str) {
    return sub($canvas) { set($canvas, $x,$y, $str) }
}

# creates a new canvas. So all @draw commands write into a new canvas. Then
# this canvas is merged into current one. Maybe the merging should be done
# explicitly, so more advanced effects are possible. Currently it is nearly
# the same as calling c_offset(). But here you can set another background.
sub c_merge($x,$y, $canvas) {
    return sub($c) {
        merge($c, $x,$y, $canvas);
        return;
    }
}

sub c_clip($x,$y, $canvas) {
    return sub($c) {
        clip($c, $x,$y, $canvas);
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

sub c_rect($tx,$ty, $bx,$by) {
    return sub($canvas) { rect($canvas, $tx,$ty, $bx,$by) }
}

# vertically splits space into same amounts
sub c_vsplit(@draws) {
    my $spaces = @draws;
    Carp::croak "vsplit: Needs at least one drawing operation" if $spaces == 0;
    return sub($canvas) { vsplit($canvas, @draws) }
}

sub c_border() {
    return sub($canvas) { border($canvas) }
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

# empty handling
{
    my $empty = empty(5,3);
    is(to_string($empty), "\n", 'to_string on empty');
    is(to_array($empty),  [],   'to_array on empty');

    set($empty, 3,0, "a");
    is(to_string($empty), "   a\n", 'empty 1');
    is(to_array($empty),  ["   a"], 'empty 2');

    set($empty, 3,1, "b");
    is(to_string($empty), "   a\n   b\n",   'empty 3');
    is(to_array($empty),  ["   a", "   b"], 'empty 4');

    set($empty, 0,2, "c");
    is(to_string($empty), "   a\n   b\nc\n",     'empty 5');
    is(to_array($empty),  ["   a", "   b", "c"], 'empty 6');
}

# bigger canvas with a lot of whitespace
{
    my $canvas = create_canvas(10,5," ");
    put($canvas, "a\nb");
    is(to_string($canvas), "a\nb\n",  'canvas with whitespace 1');
    is(to_array ($canvas), ["a","b"], 'canvas with whitespace 2');
}

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

# set_char handles special characters
{
    my $canvas = create_canvas(5,3,' ');
    fill($canvas, '.');
    set_char($canvas, 0,0, "\t");
    is(to_array($canvas), [
        '    .',
        '.....',
        '.....',
    ], 'set_char supports \t');

    my $c2 = create_canvas(5,3,'x');
    set_char($c2, 0,0, "\x00");
    set_char($c2, 1,0, "\x00");
    set_char($c2, 2,0, "\x00");
    set_char($c2, 3,0, "\x00");
    set_char($c2, 4,0, "\x00");

    merge($canvas, 0,0, $c2);
    is(to_array($canvas), [
        '    .',
        'xxxxx',
        'xxxxx',
    ], 'set_char supports zero-byte');
}

# put_char handles special characters
{
    my $canvas = create_canvas(5,3,'.');
    put_char($canvas, "1");
    put_char($canvas, "2");
    put_char($canvas, "3");
    put_char($canvas, "\b");
    put_char($canvas, "a");
    put_char($canvas, "\n");
    put_char($canvas, "f");
    put_char($canvas, "g");
    put_char($canvas, "h");
    put_char($canvas, "i");
    put_char($canvas, "\r");
    put_char($canvas, "0");
    put_char($canvas, "\b");
    put_char($canvas, "\b");
    put_char($canvas, "\b");
    put_char($canvas, "1");
    put_char($canvas, "2");
    put_char($canvas, "\x0b"); # vertical tab
    put_char($canvas, "3");
    put_char($canvas, "4");
    put_char($canvas, "5");
    put_char($canvas, "6");
    put_char($canvas, "7");
    set_pos($canvas, 0,4);
    put_char($canvas, "a");

    is(to_array($canvas), [
        '12a..',
        '12hi.',
        '..345',
        '67...',
        'a....',
    ], 'put_char with special-characters');
}

# put
{
    my $canvas = create_canvas(4,3,'.');

    put_char($canvas, 'X');
    is(
        to_string($canvas),
        "X...\n".
        "....\n".
        "....\n",
        "put 1");

    put_char($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        "....\n".
        "....\n",
        "put 2");

    set_pos($canvas, 1,1);
    put_char($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        ".X..\n".
        "....\n",
        "put 3");

    put_char($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        ".XX.\n".
        "....\n",
        "put 4");

    put_char($canvas, 'X');
    is(
        to_string($canvas),
        "XX..\n".
        ".XXX\n".
        "....\n",
        "put 5");

    put_char($canvas, 'X');
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

# put + set_pos
{
    my $canvas = create_canvas(5,3,'.');

    my $inner = create_canvas(4,2,'.');
    put($inner, 'XXXXXX');

    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        ".....",
        ".XXXX",
        ".XX..",
    ], 'put with offset');

    fill($inner, '.');
    set_pos($inner, 3,1);
    put($inner, "AAAA");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        ".....",
        ".....",
        "....A",
        ".AAA.",
    ], 'set_pos with offset');

    fill($inner, '.');
    set_pos($inner, 20,5);
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        ".....",
        ".....",
        ".....",
        ".....",
    ], 'set_pos should not expand until put()');

    put($inner, 'X');
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        ".....",
        ".....",
        ".....",
        ".....",
        ".....",
        ".....",
        ".....",
        ".X...",
    ], 'put expands, and uses offset');
}

# put() supports "\r" and "\n"
{
    my $canvas = create_canvas(5,3,'.');

    my $inner = create_canvas(4,2,'.');
    put($inner, "abc");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abc.',
        '.....',
    ], 'put ext 1');

    # with this test i found another bug. Even if it didn't
    # test \r or \n. So this test should not be deleted.
    put($inner, "de");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.e...',
    ], 'put ext 2');

    put($inner, "fg");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.efg.',
    ], 'put ext 3');

    put($inner, "\rh");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
    ], 'put - check \r');

    put($inner, "\nij");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
    ], 'put - check \n');

    put($inner, "\t1");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
    ], 'put - check \t 1');

    put($inner, "\t1");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abcd',
        '.hfg.',
        '.ij..',
        '...1.',
        '....1',
    ], 'put - check \t 2');

    set_spacing($inner, 2);
    put($inner, "\t1\t2\t3");
    merge($canvas, 1,1, $inner);
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

    put($inner, "\b4");
    merge($canvas, 1,1, $inner);
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

    put($inner, "\b5");
    merge($canvas, 1,1, $inner);
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

    put($inner, "\b\b\b0");
    merge($canvas, 1,1, $inner);
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

    put($inner, "12\x0b34");
    merge($canvas, 1,1, $inner);
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
    set_pos($canvas, 0,5);
    put($canvas, "1234");
    is(to_array($canvas), [
        '..........',
        '..........',
        '..........',
        '..........',
        '..........',
        '1234......',
    ], 'set_pos outside canvas hight, then put');

    set_pos($canvas, 20,2);
    put($canvas, "1234");
    is(to_array($canvas), [
        '..........',
        '..........',
        '..........',
        '1234......',
        '..........',
        '1234......',
    ], 'set_pos outside canvas width, then put');
}

# check if set() supports \r and \n
{
    my $canvas = create_canvas(5,3,'.');
    my $inner  = create_canvas(4,2,'.');

    set($inner, 0,0, "abc");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abc.',
        '.....',
    ], 'set - just fill to start');

    put($inner, "de");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.dec.',
        '.....',
    ], 'set - check if overwrites 1');

    set($inner, 0,0, "abc");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.abc.',
        '.....',
    ], 'set - check if overwrites 2');

    set($inner, 0,0, "abc\rd");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.dbc.',
        '.....',
    ], 'set - implements \\r');

    set($inner, 0,0, "abc\rd\ne");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.dbc.',
        '.e...',
    ], 'set - implements \\n');

    set($inner, 0,0, "abc\rd\nef\nghi");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.dbc.',
        '.ef..',
    ], 'set - does not expand height 1');

    set($inner, 0,0, "j\nklm\rn\nop");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.jbc.',
        '.nlm.',
    ], 'set - does not expand height 2');

    set($inner, 0,0, "111111\r22");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.2211',
        '.nlm.',
    ], 'set - \\r outside width');

    set($inner, 0,0, "33333\r2222222\n3");
    merge($canvas, 1,1, $inner);
    is(to_array($canvas), [
        '.....',
        '.2222',
        '.3lm.',
    ], 'set - \\n outside width');
}

# \r and \n with negative offsets
{
    my $canvas = create_canvas(5,3,'.');
    my $inner  = create_canvas(6,4,'.');

    set($inner, 0,0, "11111");
    merge($canvas, -1,-1, $inner);
    is(to_array($canvas), [
        '.....',
        '.....',
        '.....',
    ], 'set - write outside canvas');

    set($inner, 0,0, "\n12345");
    merge($canvas, -1,-1, $inner);
    is(to_array($canvas), [
        '2345.',
        '.....',
        '.....',
    ], 'set - negative offset with \\n');

    set($inner, 0,0, "\n12345\r67");
    merge($canvas, -1,-1, $inner);
    is(to_array($canvas), [
        '7345.',
        '.....',
        '.....',
    ], 'set - negative offset with \\n and \\r');

    set($inner, 0,0, "\n12345\r6789\b0");
    merge($canvas, -1,-1, $inner);
    is(to_array($canvas), [
        '7805.',
        '.....',
        '.....',
    ], 'set - backspace handling');

    set($inner, 0,0, "\n12345\r6789\b0\x0bab");
    merge($canvas, -1,-1, $inner);
    is(to_array($canvas), [
        '7805.',
        '...ab',
        '.....',
    ], 'set - vertical tab');

    set($inner, 0,0, "\n\t1234");
    merge($canvas, -1,-1, $inner);
    is(to_array($canvas), [
        '...12',
        '...ab',
        '.....',
    ], 'set - horizontal tab');
}

# spacing
{
    my $canvas = create_canvas(10,3,'.');
    is(to_array($canvas), [
        '..........',
        '..........',
        '..........',
    ], 'spacing 1');

    set($canvas, 0,0, "\t1");
    is(to_array($canvas), [
        '....1.....',
        '..........',
        '..........',
    ], 'spacing 2');

    set_spacing($canvas, 2);
    set($canvas, 0,0, "\t1");
    is(to_array($canvas), [
        '..1.1.....',
        '..........',
        '..........',
    ], 'spacing 3');

    set($canvas, 0,0, "\t1\t1");
    is(to_array($canvas), [
        '..1..1....',
        '..........',
        '..........',
    ], 'spacing 4');

    set_spacing($canvas, -5);
    set($canvas, 0,0, "\t1\t1");
    is(to_array($canvas), [
        '111..1....',
        '..........',
        '..........',
    ], 'spacing 5');
}

# check getChar, also if it correctly handles offset
{
    my $canvas = create_canvas(10, 2, '.');

    set($canvas, 0,0, "0123456789");
    set($canvas, 0,1, "abcdefghij");

    is(get_char($canvas, 5,0), '5', 'getChar 2');
    is(get_char($canvas, 9,0), '9', 'getChar 3');
    is(get_char($canvas, 0,0), '0', 'getChar 1');
    is(get_char($canvas, 0,1), 'a', 'getChar 4');
    is(get_char($canvas, 5,1), 'f', 'getChar 5');
    is(get_char($canvas, 9,1), 'j', 'getChar 6');
}

# set with negative writes
{
    my $canvas = create_canvas(3,3,'.');
    set($canvas, -1,-1, "XXX\nX");
    is(
        to_string($canvas), "X..\n...\n...\n",
        'set with negative offset');
}

# check iter()
{
    my $canvas = create_canvas(3,3,'.');
    my @iters;
    iter($canvas, sub { push @iters, [@_] });
    is(
        \@iters,
        [
            [0,0, "."], [1,0, "." ], [2,0, "." ],
            [0,1, "."], [1,1, "." ], [2,1, "." ],
            [0,2, "."], [1,2, "." ], [2,2, "." ],
        ],
        'iter after offset');
}

# check iter_line
{
    my $canvas = create_canvas(3,3,'.');

    my @sizes;
    iter_line($canvas, sub { push @sizes, [@_] });
    is(
        \@sizes,
        [
            [0,0, "..."],
            [0,1, "..."],
            [0,2, "..."],
        ],
        'iter_line with offset');
}

# check map()
{
    my $canvas = create_canvas(3,3,'.');
    set($canvas, 0,0, "012");
    set($canvas, 0,1, "345");
    set($canvas, 0,2, "678");

    my @iters;
    cmap($canvas, sub($x,$y,$char) {
        push @iters, [$x,$y];
        return $char + 1;
    });
    is(
        \@iters,
        [
            [0,0], [1,0], [2,0],
            [0,1], [1,1], [2,1],
            [0,2], [1,2], [2,2],
        ],
        'map');

    is(to_string($canvas), "123\n456\n789\n", 'string after canvas');
}

# set_wrap
{
    my $canvas = create_canvas(10,3,'.');

    set_wrap($canvas, 0,1, "1234567890abcde");
    is(to_array($canvas), [
        '..........',
        '1234567890',
        'abcde.....',
    ], 'set_wrap 1');

    put($canvas, 'fghi');
    is(to_array($canvas), [
        'fghi......',
        '1234567890',
        'abcde.....',
    ], 'set_wrap 2');

    set_wrap($canvas, 5,1, "xxx");
    is(to_array($canvas), [
        'fghi......',
        '12345xxx90',
        'abcde.....',
    ], 'set_wrap 3');

    put($canvas, "zzz");
    is(to_array($canvas), [
        'fghizzz...',
        '12345xxx90',
        'abcde.....',
    ], 'set_wrap 4');

    set_wrap($canvas, 5,2, "yyyyyy");
    is(to_array($canvas), [
        'fghizzz...',
        '12345xxx90',
        'abcdeyyyyy',
        'y.........',
    ], 'set_wrap 5');
}

# border
{
    my $canvas = create_canvas(10,3, '.');
    border($canvas);
    set($canvas, 2,1, 'Hello');
    is(to_array($canvas), [
        '┌────────┐',
        '│.Hello..│',
        '└────────┘',
    ], 'border');
}

# place
{
    my $canvas = create_canvas(10,6, '.');

    place($canvas, 0,0, 10, 'l',      'Hello');
    place($canvas, 0,1, 10, 'left',   'Hello');
    place($canvas, 0,2, 10, 'c',      'Hello');
    place($canvas, 0,3, 10, 'center', 'Hello');
    place($canvas, 0,4, 10, 'r',      'Hello');
    place($canvas, 0,5, 10, 'right',  'Hello');
    is(to_array($canvas), [
        'Hello.....',
        'Hello.....',
        '..Hello...',
        '..Hello...',
        '.....Hello',
        '.....Hello',
    ], 'place - $str < $length');

    place($canvas, 0,0, 10, 'R',      'Hello');
    place($canvas, 0,1, 10, 'Right',  'Hello');
    place($canvas, 0,2, 10, 'C',      'Hello');
    place($canvas, 0,3, 10, 'Center', 'Hello');
    place($canvas, 0,4, 10, 'L',      'Hello');
    place($canvas, 0,5, 10, 'Left',   'Hello');
    is(to_array($canvas), [
        '.....Hello',
        '.....Hello',
        '..Hello...',
        '..Hello...',
        'Hello.....',
        'Hello.....',
    ], 'place - check ignorecase of $where');

    place($canvas, 0,0, 10, 'l',      '1234567890abcdef');
    place($canvas, 0,1, 10, 'left',   '1234567890abcdef');
    place($canvas, 0,2, 10, 'c',      '1234567890abcdef');
    place($canvas, 0,3, 10, 'center', '1234567890abcdef');
    place($canvas, 0,4, 10, 'r',      '1234567890abcdef');
    place($canvas, 0,5, 10, 'right',  '1234567890abcdef');
    is(to_array($canvas), [
        '1234567890',
        '1234567890',
        '4567890abc',
        '4567890abc',
        '7890abcdef',
        '7890abcdef',
    ], 'place - $str > $length and even cutoff');

    place($canvas, 0,0, 10, 'l',      '1234567890abcde');
    place($canvas, 0,1, 10, 'left',   '1234567890abcde');
    place($canvas, 0,2, 10, 'c',      '1234567890abcde');
    place($canvas, 0,3, 10, 'center', '1234567890abcde');
    place($canvas, 0,4, 10, 'r',      '1234567890abcde');
    place($canvas, 0,5, 10, 'right',  '1234567890abcde');
    is(to_array($canvas), [
        '1234567890',
        '1234567890',
        '34567890ab',
        '34567890ab',
        '67890abcde',
        '67890abcde',
    ], 'place - $str > $length and uneven cutoff');
}

# check merge, and how it handles offsets
{
    my $first  = create_canvas(5,5,'.');
    my $second = create_canvas(3,3,'x');

    merge($first, 0,0, $second);
    is(to_string($first), "xxx..\nxxx..\nxxx..\n.....\n.....\n", "merge 1");

    fill($first, '.');
    merge($first, 1,1, $second);
    is(to_string($first), ".....\n.xxx.\n.xxx.\n.xxx.\n.....\n", "merge 2");

    fill($first, '.');
    merge($first, -1,-1, $second);
    is(to_string($first), "xx...\nxx...\n.....\n.....\n.....\n", "merge 3");
}

# merge/clip empty canvas
{
    my $c1 = create_canvas(5,5,'.');
    my $c2 = empty(5,5);

    my $new = copy($c1);
    merge($new, 0,0, $c2);
    is(to_string($new), to_string($c1), 'merging empty canvas has no effect 1');

    $new = copy($c2);
    merge($new, 0,0, $c1);
    is(to_string($new), to_string($c1), 'merging empty canvas has no effect 2');

    $new = copy($c1);
    clip($new, 0,0, $c2);
    is(to_string($new), to_string($c1), 'cliping empty canvas has no effect 1');

    $new = copy($c2);
    clip($new, 0,0, $c1);
    is(to_string($new), to_string($c1), 'cliping empty canvas has no effect 2');

    # if this tests fails then the above copy instructions are not correct.
    # merge or clip does mutation on second value, or transparent values are not
    # correctly handled
    is(to_array($c1), [
        '.....',
        '.....',
        '.....',
        '.....',
        '.....',
    ], 'check if $c1 is still the same');
}


########################
### Combinator API Tests
########################

# horizontal/vertical lines
{
    my $canvas = create_canvas(5,5,'.');

    vline($canvas, 1, 1,3);
    vline($canvas, 3, 1,3);
    is(to_array($canvas), [
        '.....',
        '.│.│.',
        '.│.│.',
        '.│.│.',
        '.....',
    ], 'vline');

    clear_canvas($canvas);
    hline($canvas, 1, 1,3);
    hline($canvas, 3, 1,3);
    is(to_array($canvas), [
        '.....',
        '.───.',
        '.....',
        '.───.',
        '.....',
    ], 'hline');

    clear_canvas($canvas);
    vline($canvas, 1, 1,3);
    vline($canvas, 3, 1,3);
    hline($canvas, 1, 1,3);
    hline($canvas, 3, 1,3);
    is(to_array($canvas), [
        '.....',
        '.───.',
        '.│.│.',
        '.───.',
        '.....',
    ], 'hline & vline 1');

    clear_canvas($canvas);
    hline($canvas, 1, 1,3);
    hline($canvas, 3, 1,3);
    vline($canvas, 1, 1,3);
    vline($canvas, 3, 1,3);
    is(to_array($canvas), [
        '.....',
        '.│─│.',
        '.│.│.',
        '.│─│.',
        '.....',
    ], 'hline & vline 2');
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

my $canvas = c_empty(20,20, c_fill('a'));
is(
    c_string(10,10,'.', c_clip(0,0, $canvas)),
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

my $with_corner = c_empty(10,10,
    c_merge(0,0, $canvas),
    c_set(0,0, 'b'),
    c_set(9,0, 'b'),
    c_set(0,9, 'b'),
    c_set(9,9, 'b')
);
is(
    c_string(10,10,'.', c_clip(0,0, $with_corner)),
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
        c_clip(0,0, $with_corner),
        c_set(-1,0, 'c'),
        c_set(10,0, 'c'),
        c_set(5,-1, 'c'),
        c_set(5,10, 'c')),
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

my $box = c_run(4,4,'X');
is(
    c_string(10,10,'.',
        c_clip(0,0, $with_corner),
        c_set(-1,0, 'c'),
        c_set(10,0, 'c'),
        c_set(5,-1, 'c'),
        c_set(5,10, 'c'),
        c_clip(3,3, $box),
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
        c_clip(0,0, $with_corner),
        c_set(-1,0, 'c'),
        c_set(10,0, 'c'),
        c_set(5,-1, 'c'),
        c_set(5,10, 'c'),
        c_clip( 3, 3, $box), # middle
        c_clip( 3,-3, $box), # top
        c_clip(-3, 3, $box), # left
        c_clip( 9, 3, $box), # right
        c_clip( 3, 9, $box), # bottom
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
    c_run(4,4,' ',
        c_make_transparent,
        c_set(0,0,'a'),
        c_set(3,0,'a'),
        c_set(0,3,'a'),
        c_set(3,3,'a'));

is(
    c_string(4,4," ",c_clip(0,0,$cbox)),
    "a  a\n".
    "\n".
    "\n".
    "a  a\n",
    'c_and 1');

is(
    c_string(4,4,".",c_clip(0,0, $cbox)),
    "a..a\n".
    "....\n".
    "....\n".
    "a..a\n",
    'c_and 2');

is(
    c_string(6,6,".",c_clip(0,0, $cbox)),
    "a..a..\n".
    "......\n".
    "......\n".
    "a..a..\n".
    "......\n".
    "......\n",
    'c_and 3');

is(
    c_string(8,6,".", c_clip(2,2,$cbox)),
    "........\n".
    "........\n".
    "..a..a..\n".
    "........\n".
    "........\n".
    "..a..a..\n",
    'c_and + c_offset');

{
    my $box =
        c_run(3,3, "o",
            c_set(0,0, "X"), c_set(2,0, "X"),
            c_set(0,2, "X"), c_set(2,2, "X"));

    is(
        c_string(9,9,".",
            c_clip(0,0, $box),
            c_clip(6,0, $box),
            c_clip(0,6, $box),
            c_clip(6,6, $box)),
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
        c_merge(0,0,
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
    c_string(4,4,".",
        c_merge(0,0,
            c_fromAoA([
                [qw/o o o o/],
                [qw/o o o o/],
                [qw/o o o o/],
                [qw/o o o o/],
            ])),
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
        c_merge(0,0,
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
    c_string(4,4,'.',
        c_merge(0,0,
            c_fromArray([
                "oooo",
                "oooo",
                "oooo",
                "oooo",
            ])),
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
        c_merge(0,0, c_fromAoA([
            [qw/X o o o/],
            [qw/o X o o/],
            [qw/o o X o/],
            [qw/o o o X/],
        ])),

        c_merge(5,0, c_fromArray([
            "Xooo",
            "oXoo",
            "ooXo",
            "oooX",
        ]))),
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
    c_string(5,5,'.', c_rect(0,0, 4,4)),
    c_string(5,5,'.', c_merge(0,0, c_fromArray([
        "┌───┐",
        "│...│",
        "│...│",
        "│...│",
        "└───┘",
    ]))),
    'c_rect 1');

is(
    c_string(5,5,".", c_rect(1,1, 3,3)),
    ".....\n".
    ".┌─┐.\n".
    ".│.│.\n".
    ".└─┘.\n".
    ".....\n",
    'c_rect 2');

is(
    c_string(4,4,".", c_rect(1,1, 2,2)),
    "....\n".
    ".┌┐.\n".
    ".└┘.\n".
    "....\n",
    'c_rect 3');

is(
    c_string(5,5,".", c_border),
    "┌───┐\n".
    "│...│\n".
    "│...│\n".
    "│...│\n".
    "└───┘\n",
    'c_border 1');

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