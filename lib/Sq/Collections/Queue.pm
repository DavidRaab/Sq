package Queue;
use 5.036;
use subs 'foreach';
use Scalar::Util ();
use List::Util ();
use Carp ();
use DDP;

sub new($class) {
    return bless({
        start => 0,
        stop  => 0,
        count => 16,
        data  => [(undef) x 16],
    }, 'Queue');
}

sub count($self) {
    my ($start, $stop) = ( $self->{start}, $self->{stop} );
    if ( $start < $stop ) {
        return $stop - $start;
    }
    elsif ( $start == $stop ) {
        return 0;
    }
    else {
    }
}

sub add_one($self, $x) {
    my ($start, $stop) = ( $self->{start}, $self->{stop} );

    # double size and copy to new array when count is not enough
    raise($self) if count($self) == $self->{count};

    if ( $start == $stop ) {
        $self->{data}[0] = $x;
        $self->{start}   = 0;
        $self->{stop}    = 1;
    }
    if ( $start < $stop ) {
        $self->{data}[$stop] = $x;
        $self->{stop}++;
    }
    else {

    }
    return $self;
}

sub add($self, @xs) {
    $self->add_one($_) for @xs;
    return $self;
}

sub remove($self) {
    my ($start, $stop) = ( $self->{start}, $self->{stop} );

    if ( $start < $stop ) {
        my $x = $self->{data}[$start];
        $self->{data}[$start] = undef;
        $self->{start}++;
        return $x;
    }
    elsif ( $start == $stop ) {
        return;
    }
    else {
    }
}

sub raise($self) {
    my $new_count = $self->{count} * 2;
    my @new_data  = (undef) x $new_count;
    my $idx = 0;
    iter($self, sub($x) {
        $new_data[$idx++] = $x;
    });
    $self->{count} = $new_count;
    $self->{start} = 0;
    $self->{stop}  = $idx;
    $self->{data}  = \@new_data;
    return $self;
}

sub iter($self, $f) {
    my ($start, $stop) = ( $self->{start}, $self->{stop} );
    if ( $start < $stop ) {
        for (my $idx=$start; $idx < $stop; $idx++) {
            $f->( $self->{data}[$idx] );
        }
    }
    elsif ( $start == $stop ) {
        # empty queue; do nothing
    }
    else {
        my $end = $self->{data}->$#*;
        for (my $idx=$start; $idx <= $end; $idx++) {
            $f->( $self->{data}[$idx] );
        }
        for (my $idx=0; $idx < $stop; $idx++) {
            $f->( $self->{data}[$idx] );
        }
    }
    return;
}

sub iteri($self, $f) {
    my $idx = 0;
    iter($self, sub($x) {
        $f->($x, $idx++);
    });
    return;
}

sub to_array($self) {
    my @array;
    iter($self, sub($x) {
        push @array, $x;
    });
    return bless(\@array, 'Array');
}

1;