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
        count => 0,
        data  => [(undef) x 16],
    }, 'Queue');

    $queue->add(@xs);
    return $queue;
}

# simple getters
sub capacity($self) { return scalar $self->{data}->@* }
sub count($self)    { return        $self->{count}    }

sub add_one($self, $x) {
    # double size and copy to new array when capacity is not enough
    raise($self) if count($self) == capacity($self);

    my ($start, $stop) = ( $self->{start}, $self->{stop} );
    my $capacity = capacity($self);

    # on empty queue
    if ( $self->{count} == 0 ) {
        $self->{data}[0] = $x;
        $self->{start}   = 0;
        $self->{stop}    = 1;
    }
    # when still ordered and queue can be read from start to stop
    elsif ( $start < $stop ) {
        # when capacity is enough, but $stop reached end of storage array
        # then we need to wrap around and save item at index 0
        if ( $stop == $capacity ) {
            $self->{data}[0] = $x;
            $self->{stop}    = 1;
        }
        else {
            $self->{data}[$stop] = $x;
            $self->{stop}++;
        }
    }
    # when queue starts somewhere in the middle wraps around and continues at 0
    else {
        $self->{data}[$stop] = $x;
        $self->{stop}++;
    }

    $self->{count}++;
    return $self;
}

sub add($self, @xs) {
    $self->add_one($_) for @xs;
    return $self;
}

sub remove_one($self) {
    my ($start, $stop) = ( $self->{start}, $self->{stop} );

    if ( $self->{count} > 0 ) {
        # element to return
        my $x = $self->{data}[$start];

        # delete element in storage
        $self->{data}[$start] = undef;
        $self->{count}--;

        # $start must be either increased or set to 0
        if ( $start == capacity($self) ) {
            $self->{start} = 0;
        }
        else {
            $self->{start}++;
        }

        return $x;
    }
    else {
        return;
    }
}

sub remove($self, $amount = 1) {
    if ( $amount == 1 ) {
        return remove_one($self);
    }
    elsif ( $amount <= 1 ) {
        return;
    }
    else {
        my @data;
        for ( 1 .. $amount ) {
            push @data, remove_one($self);
        }
        return @data;
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
    if ( $self->{count} == 0 ) {
        # empty queue; do nothing
    }
    elsif ( $start < $stop ) {
        for (my $idx=$start; $idx < $stop; $idx++) {
            $f->( $self->{data}[$idx] );
        }
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