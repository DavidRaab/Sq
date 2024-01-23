package Array;
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort';
use Scalar::Util ();
use List::Util ();
use Carp ();

#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create sequences                          #
#-----------------------------------------------------------------------------#

sub empty($class) {
    return bless([], 'Array')
}

# wraps all function arguments into Array. Stops at first undef
sub wrap($class, @array) {
    my @copy;
    for my $x ( @array ) {
        last if not defined $x;
        push @copy, $x;
    }
    return bless(\@copy, 'Array');
}

# concatenate arrays into a flattened array
sub concat($class, @arrays) {
    my @new;
    for my $array ( @arrays ) {
        push @new, @$array;
    }
    return bless(\@new, 'Array');
}

# Creates an Array with $count by passing the index to a function creating
# the current element
sub init($class, $count, $f) {
    return bless([map { $f->($_) } 0 .. ($count-1)], 'Array');
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
    Carp::croak '$step is 0. Will run forever.' if $step == 0;

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


#-----------------------------------------------------------------------------#
# METHODS                                                                     #
#           functions operating on Seq and returning another Seq              #
#-----------------------------------------------------------------------------#

sub bind($array, $f) {
    my @new;
    for my $x ( @$array ) {
        push @new, @{ $f->($x) };
    }
    return bless(\@new, 'Array');
}

sub flatten($array) {
    return bind($array, \&Sq::id);
}

# append : Array<'a> -> Array<'a> -> Array<'a>
sub append($array1, $array2) {
    return bless([@$array1, @$array2], 'Array');
}

# rev : Array<'a> -> Array<'a>
sub rev($array) {
    return bless([reverse @$array], 'Array');
}

# map : Array<'a> -> ('a -> 'b) -> Array<'b>
sub map($array, $f) {
    local $_;
    return bless([map { $f->($_) } @$array], 'Array');
}

sub mapi($array, $f) {
    my @new;
    my $idx = 0;
    for my $x ( @$array ) {
        push @new, $f->($x, $idx++);
    }
    return bless(\@new, 'Array');
}

sub choose($array, $f) {
    my @new;
    for my $x ( @$array ) {
        my $value = $f->($x);
        if ( defined $value ) {
            push @new, $value;
        }
    }
    return bless(\@new, 'Array');
}

# filter : Array<'a> -> ('a -> bool) -> Array<'a>
sub filter($array, $predicate) {
    local $_;
    return bless([grep { $predicate->($_) } @$array], 'Array');
}

sub skip($array, $amount) {
    return bless([$array->@[$amount .. $array->$#*]], 'Array');
}

# take : Array<'a> -> Array<'a>
sub take($array, $amount) {
    my @array;
    for (my $idx=0; $idx < $amount; $idx++ ) {
        my $x = $array->[$idx];
        last if !defined $x;
        push @array, $x;
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

# adds index to an array
sub indexed($array) {
    my $idx = 0;
    my @new;
    for my $x ( @$array ) {
        push @new, [$idx++, $x];
    }
    return bless(\@new, 'Array');
}

# zip : Array<'a> -> Array<'b> -> Array<'a * 'b>
sub zip($array1, $array2) {
    my @new;
    my $idx = 0;
    while (1) {
        my $x = $array1->[$idx];
        my $y = $array2->[$idx];
        last if !defined($x) or !defined($y);
        $idx++;
        push @new, [$x,$y];
    }
    return bless(\@new, 'Array');
}

#-----------------------------------------------------------------------------#
# SIDE-EFFECTS                                                                #
#    functions that have side-effects or produce side-effects. Those are      #
#    immediately executed, usually consuming all elements of Seq at once.     #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# CONVERTER                                                                   #
#         Those are functions converting Array to none Array types            #
#-----------------------------------------------------------------------------#

sub reduce($array, $default, $f) {
    return $default    if @$array == 0;
    return $array->[0] if @$array == 1;
    my $init = $array->[0];
    for (my $idx=1; $idx < @$array; $idx++) {
        $init = $f->($init, $array->[$idx]);
    }
    return $init;
}

sub sum($array) {
    my $sum = 0;
    for my $x ( @$array ) {
        $sum += $x;
    }
    return $sum;
}

sub sum_by($array, $mapper) {
    my $sum = 0;
    for my $x ( @$array ) {
        $sum += $mapper->($x);
    }
    return $sum;
}

sub str_join($array, $sep) {
    return join($sep, @$array);
}

sub to_hash($array, $mapper) {
    my %hash;
    for my $x ( @$array ) {
        my ($key, $value) = $mapper->($x);
        $hash{$key} = $value;
    }
    return \%hash;
}

sub to_hash_of_array($array, $mapper) {
    my %hash;
    for my $x ( @$array ) {
        my ($key, $value) = $mapper->($x);
        push @{$hash{$key}}, $value;
    }
    return \%hash;
}

sub distinct($array) {
    my %seen;
    my @new;
    for my $value ( @$array ) {
        if ( not exists $seen{$value} ) {
            push @new, $value;
            $seen{$value} = 1;
        }
    }
    return bless(\@new, 'Array');
}

sub distinct_by($array, $get_key) {
    my %seen;
    my @new;
    for my $value ( @$array ) {
        my $key = $get_key->($value);
        if ( not exists $seen{$key} ) {
            push @new, $value;
            $seen{$key} = 1;
        }
    }
    return bless(\@new, 'Array');
}

sub find($array, $default, $predicate) {
    for my $x ( @$array ) {
        return $x if $predicate->($x);
    }
    return $default;
}

1;