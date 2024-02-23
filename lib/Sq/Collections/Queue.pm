package Queue;
use 5.036;
use subs 'foreach';
use Scalar::Util ();
use List::Util ();
use Carp ();
use DDP;

sub new($class, @xs) {
    my $queue = bless({
        start => 0,
        stop  => 0,
        data  => [(undef) x 16],
    }, 'Queue');

    $queue->add(@xs);
    return $queue;
}

sub capacity($self) {
    return scalar @{ $self->{data} };
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

    # double size and copy to new array when capacity is not enough
    raise($self) if count($self) == $self->capacity;

    # on empty queue
    if ( $start == $stop ) {
        $self->{data}[0] = $x;
        $self->{start}   = 0;
        $self->{stop}    = 1;
    }
    # when still ordered and queue can be read from start to stop
    elsif ( $start < $stop ) {
        $self->{data}[$stop] = $x;
        $self->{stop}++;
    }
    # when queue starts somewhere in the middle and continues at 0
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
    my @new_data = (undef) x ( $self->capacity * 2 );
    my $idx      = 0;
    iter($self, sub($x) {
        $new_data[$idx++] = $x;
    });
    $self->{start} = 0;
    $self->{stop}  = $idx;
    $self->{data}  = \@new_data;
    return;
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

sub foreach($self, $f) {
    iter($self, $f);
    return;
}

sub iteri($self, $f) {
    my $idx = 0;
    iter($self, sub($x) {
        $f->($x, $idx++);
    });
    return;
}

sub foreachi($self, $f) {
    iteri($self, $f);
    return;
}

sub to_array($self) {
    my @array; iter($self, sub($x) {
        push @array, $x;
    });
    return bless(\@array, 'Array');
}

1;