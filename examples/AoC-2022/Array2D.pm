package Array2D;
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use List::Util qw(max);

sub from_aoa($class, $aoa) {
    return bless({
        data   => [map { @$_ } @$aoa],
        width  => max(map { scalar @$_ } @$aoa),
        height => scalar @$aoa,
    }, $class);
}

sub init ($class, $width, $height, $f) {
    my @arr;
    for my $y ( 0 .. $height-1 ) {
        for my $x ( 0 .. $width-1 ) {
            push @arr, $f->($x,$y);
        }
    }

    return bless({
        data   => \@arr,
        width  => $width,
        height => $height,
    }, $class);
}

sub height ($self) { return $self->{height} }
sub width  ($self) { return $self->{width}  }

sub is_inside ($self, $x, $y) {
    if ( $x >= 0 && $y >= 0 && $x < $self->{width} && $y < $self->{height} ) {
        return 1;
    }
    return;
}

sub get($self, $x, $y) {
    if ( $x >= 0 && $y >= 0 && $x < $self->{width} && $y < $self->{height} ) {
        return $self->{data}[$y * $self->{width} + $x];
    }
    return;
}

sub set($self, $x, $y, $value) {
    $self->{data}[$y * $self->{width} + $x] = $value;
}

sub reduce ($self, $init, $f) {
    for my $y ( 0 .. $self->height - 1 ) {
        for my $x ( 0 .. $self->width - 1 ) {
            $init = $f->($init, $self->get($x,$y), $x, $y);
        }
    }
    return $init;
}

sub iter ($self, $f) {
    for my $y ( 0 .. $self->height - 1 ) {
        for my $x ( 0 .. $self->width - 1 ) {
            $f->($x, $y, $self->get($x,$y));
        }
    }
}

sub map ($self, $f) {
    my @new;
    $self->iter(sub($x, $y, $val) {
        push @new, $f->($val);
    });
    return bless({
        data   => \@new,
        width  => $self->width,
        height => $self->height,
    }, ref $self);
}

sub show($self, $fmt) {
    my $str = "";
    for my $y ( 0 .. $self->height-1 ) {
        my @row;
        for my $x ( 0 .. $self->width-1 ) {
            push @row, $fmt->($x, $y, $self->get($x, $y));
        }
        $str .= join("", @row) . "\n";
    }
    return $str;
}

1;