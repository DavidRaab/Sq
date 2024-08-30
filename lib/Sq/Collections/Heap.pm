package Heap;
use 5.036;

# cmpf is a typical Perl-like comparison function. That means it must return
# which element is smaller. It does so by either returning -1, 0 or 1.
# -1 means left element is smaller. 0 means both elements are equal,
# and 1 means right element is smaller.
sub new($class, $cmpf) {
    return bless({
        data => [undef],
        cmpf => $cmpf,
    }, 'Heap');
}

sub count($heap) {
    return $heap->{data}->@* - 1;
}

sub add($heap, @values) {
    for my $x ( @values ) {
        add_one($heap, $x);
    }
    return;
}

sub add_one($heap, $x) {
    push $heap->{data}->@*, $x;
    heap_up($heap);
    return;
}

sub head($heap) {
    my $data = $heap->{data};
    return @$data > 1 ? $data->[1] : ();
}

sub heap_up($heap) {
    my $data = $heap->{data};
    my $cmpf = $heap->{cmpf};

    # start with last element
    my $current = @$data - 1;

    while (1) {
        # abort when we reached top
        return if $current == 1;

        # if current is smaller
        my $parent = int ($current / 2);
        if ( $cmpf->($data->[$current], $data->[$parent]) == -1 ) {
            my $tmp = $data->[$parent];
            $data->[$parent]  = $data->[$current];
            $data->[$current] = $tmp;
            $current = $parent;
        }
        # abort when parent is equal or smaller
        else {
            return;
        }
    }

    return;
}

sub remove($heap) {
    my $data = $heap->{data};
    return if @$data == 1;

    my $first  = $data->[1];
    $data->[1] = $data->[ $data->$#* ];
    pop @$data;

    heap_down($heap);
    return $first;
}

sub remove_all($heap) {
    my @array;
    while ( my $x = remove($heap) ) {
        push @array, $x;
    }
    return wantarray ? @array : \@array;
}

sub heap_down($heap) {
    my $data = $heap->{data};
    my $cmpf = $heap->{cmpf};

    # start with first element
    my $current = 1;
    my $max     = @$data - 1;

    while (1) {
        my $left  = $current * 2;
        my $right = $current * 2 + 1;
        return if $left > $max;

        # when we have left and right child we need to check both childs
        # and swap with the one that is smaller.

        # when right is greater than max, we only have a left-child
        if ( $right > $max ) {
            # when left is smaller than swap
            if ( $cmpf->($data->[$current], $data->[$left]) == 1 ) {
                my $tmp           = $data->[$left];
                $data->[$left]    = $data->[$current];
                $data->[$current] = $tmp;
                $current = $left;
                next;
            }
            # otherwise we reached end and can finish
            return;
        }
        else {
            my $l = $data->[$left];
            my $r = $data->[$right];

            # swap with left
            my $cmp = $cmpf->($l,$r);
            if ( $cmp == -1 || $cmp == 0 ) {
                $data->[$left]    = $data->[$current];
                $data->[$current] = $l;
                $current          = $left;
            }
            # swap with right
            else {
                $data->[$right]   = $data->[$current];
                $data->[$current] = $r;
                $current          = $right;
            }
        }
    }

    return;
}

1;