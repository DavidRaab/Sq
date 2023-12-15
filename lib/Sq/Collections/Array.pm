package Array;
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort';
use Scalar::Util;
use List::Util;
use Carp;

sub empty {
    return [];
}

# Array->unfold : 'State -> ('State -> Option<ListContext<'a, 'State>>) -> Array<'a>
sub unfold($class, $state, $f) {
    my $s = $state;
    my $x;
    my @array;

    while (1) {
        ($x, $s) = $f->($s);
        last if not defined $x;
        push @array, $x;
    }

    return bless(\@array, 'Array');
}

# Array->range_step : float -> float -> float -> Array<float>
sub range_step($class, $start, $step, $stop) {
    # Ascending Order
    if ( $start <= $stop ) {
        return unfold('Array', $start, sub($current) {
            return $current, $current+$step if $current <= $stop;
            return undef;
        });
    }
    # Descending Order
    else {
        return unfold('Array', $start, sub($current) {
            return $current, $current-$step if $current >= $stop;
            return undef;
        });
    }
}

# Array->range : float -> float -> Array<float>
sub range($class, $start, $stop) {
    return range_step('Array', $start, 1, $stop);
}

# Array->from_array : Array<'a> -> Array<'a>
sub from_array($class, $xs) {
    return bless($xs, 'Array');
}

# rev : Array<'a> -> Array<'a>
sub rev($array) {
    my @array;
    my $idx  = $array->$#*;
    while ( $idx >= 0 ) {
        push @array, $array->[$idx--];
    }
    return bless(\@array, 'Array');
}

# map : Array<'a> -> ('a -> 'b) -> Array<'b>
sub map($array, $f) {
    local $_;
    return bless([map { $f->($_) } @$array], 'Array');
}

# filter : Array<'a> -> ('a -> bool) -> Array<'a>
sub filter($array, $predicate) {
    local $_;
    return bless([grep { $predicate->($_) } @$array], 'Array');
}

# take : Array<'a> -> Array<'a>
sub take($array, $amount) {
    my @array;
    for (my $idx=0; $idx < $amount; $idx++ ) {
        push @array, $array->[$idx];
    }
    return bless(\@array, 'Array');
}

# count : Array<'a> -> int
sub count($array) {
    return scalar @{ $array };
}

# fold : Array<'a> -> 'State -> ('State -> 'a -> 'State) -> 'State
sub fold($array, $state, $folder) {
    for my $x ( @$array ) {
        $state = $folder->($state, $x);
    }
    return $state;
}

# fold : Array<'a> -> 'State -> ('State -> 'a -> 'State) -> 'State
sub fold_mut($array, $state, $folder) {
    for my $x ( @$array ) {
        $folder->($state, $x);
    }
    return $state;
}

# Expands an array into its values
sub expand($array) {
    return @$array;
}

sub first($array, $default) {
    return $default if @$array == 0;
    return $array->[0];
}

sub last($array, $default) {
    return $default if @$array == 0;
    return $array->[-1];
}

1;