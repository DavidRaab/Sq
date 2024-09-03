package Heap;
use 5.036;

# cmpf is a typical Perl-like comparison function. That means it must return
# which element is smaller. It does so by either returning -1, 0 or 1.
# -1 means left element is smaller. 0 means both elements are equal,
# and 1 means right element is smaller.
sub new($class, $cmpf) {
    die "You must pass a comparison function." if not defined $cmpf;
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
    my $data = $heap->{data};
    my $cmpf = $heap->{cmpf};

    # add new element to end
    push @$data, $x;

    # compare with parent and swap if current is smaller, repeat
    # until current is greater than parent
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

sub head($heap) {
    my $data = $heap->{data};
    return @$data > 1 ? $data->[1] : ();
}

sub remove($heap) {
    my $data = $heap->{data};
    my $cmpf = $heap->{cmpf};

    # nothing to remove when data is empty
    return if @$data == 1;

    # save element that is later returned
    my $return = $data->[1];

    # overwrite first element with last one, then move element down
    # until heap consistency is reached again.
    $data->[1] = $data->[ $data->$#* ];
    pop @$data;

    # start with first element
    my $current = 1;
    my $max     = @$data - 1;

    # Declaration outside loop for maximum performance
    my ($left, $right, $l, $r, $cmp);

    while (1) {
        $left  = $current << 1;
        $right = $left + 1;
        return $return if $left > $max;

        # when we have left and right child we need to check both childs
        # and swap with the one that is smaller.

        # when right is greater than max, we only have a left-child
        if ( $right > $max ) {
            # when $left is smaller than $current than swap
            if ( $cmpf->($data->[$current], $data->[$left]) == 1 ) {
                my $tmp           = $data->[$left];
                $data->[$left]    = $data->[$current];
                $data->[$current] = $tmp;
                $current = $left;
                next;
            }

            # otherwise we reached end and can finish
            return $return;
        }
        # when we have left and right child
        else {
            # check if left or right is smaller
            $l = $data->[$left];
            $r = $data->[$right];
            $cmp = $cmpf->($l,$r);

            # left value is smaller
            if ( $cmp == -1 || $cmp == 0 ) {
                # check if $current is smaller than $left
                if ( $cmpf->($data->[$current], $l) == 1 ) {
                    $data->[$left]    = $data->[$current];
                    $data->[$current] = $l;
                    $current          = $left;
                    next;
                }
                return $return;
            }
            # right value is smaller
            else {
                # check if $current is smaller than $right
                if ( $cmpf->($data->[$current], $r) == 1 ) {
                    $data->[$right]   = $data->[$current];
                    $data->[$current] = $r;
                    $current          = $right;
                    next;
                }
                return $return;
            }
        }
    }

    return $return;
}

sub remove_all($heap) {
    my $count = count($heap);
    my @array;
    for (my $i=0; $i < $count; $i++) {
        push @array, remove($heap);
    }
    return wantarray ? @array : \@array;
}

sub show_tree($heap, $fmt=sub($x) { $x }) {
    my $data  = $heap->{data};
    my $count = count($heap);
    my $level = 0;

    NEXT_LEVEL:
    $level++;
    my $min = int (2 ** ($level - 1));
    my $max = int ((2 ** $level) - 1);

    printf "%d: ", $level;
    for my $idx ( $min .. $max ) {
        my $x = $data->[$idx];
        goto ABORT if !defined $x;
        printf "%s ", $fmt->($data->[$idx]);
    }
    print "\n";

    goto NEXT_LEVEL if $min < $count;
    print "\n";
    return;

    ABORT:
    print "\n";
    return;
}

1;