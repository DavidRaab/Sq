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

sub replicate($class, $count, $initial) {
    return bless([($initial) x $count], 'Array');
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

sub sort($array, $comparer) {
    local ($a, $b);
    my @sorted = CORE::sort { $comparer->($a, $b) } @$array;
    return bless(\@sorted, 'Array');
}

sub sort_by($array, $comparer, $get_key) {
    local ($a, $b, $_);
    my @sorted =
        CORE::map  { $_->[1] }
        CORE::sort { $comparer->($a->[0], $b->[0]) }
        CORE::map  { [$get_key->($_), $_] }
            @$array;
    return bless(\@sorted, 'Array');
}

sub fsts($array) {
    my @new;
    for my $x ( @$array ) {
        push @new, $x->[0];
    }
    return bless(\@new, 'Array');
}

sub snds($array) {
    my @new;
    for my $x ( @$array ) {
        push @new, $x->[1];
    }
    return bless(\@new, 'Array');
}

sub to_array_of_array($array) {
    return $array;
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

sub regex_match($array, $regex, $picks) {
    my @new;
    for my $str ( @$array ) {
        if ( $str =~ $regex ) {
            my @matches;
            for my $i ( @$picks ) {
                if    ( $i ==  0 ) { push @matches,  $0 }
                elsif ( $i ==  1 ) { push @matches,  $1 }
                elsif ( $i ==  2 ) { push @matches,  $2 }
                elsif ( $i ==  3 ) { push @matches,  $3 }
                elsif ( $i ==  4 ) { push @matches,  $4 }
                elsif ( $i ==  5 ) { push @matches,  $5 }
                elsif ( $i ==  6 ) { push @matches,  $6 }
                elsif ( $i ==  7 ) { push @matches,  $7 }
                elsif ( $i ==  8 ) { push @matches,  $8 }
                elsif ( $i ==  9 ) { push @matches,  $9 }
                elsif ( $i == 10 ) { push @matches, $10 }
                elsif ( $i == 11 ) { push @matches, $11 }
                elsif ( $i == 12 ) { push @matches, $12 }
                elsif ( $i == 13 ) { push @matches, $13 }
                elsif ( $i == 14 ) { push @matches, $14 }
                elsif ( $i == 15 ) { push @matches, $15 }
                elsif ( $i == 16 ) { push @matches, $16 }
                elsif ( $i == 17 ) { push @matches, $17 }
                elsif ( $i == 18 ) { push @matches, $18 }
                elsif ( $i == 19 ) { push @matches, $19 }
                elsif ( $i == 20 ) { push @matches, $20 }
                else {
                    warn "regex_match can only handle picks from 0-20\n";
                }
            }
            push @new, \@matches;
        }
    }
    return bless(\@new, 'Array');
}

sub windowed($array, $window_size) {
    return empty('Array') if $window_size <= 0;

    my $length     = $window_size - 1;
    my $last_index = @$array - $length;
    my @new;
    for (my $index=0; $index < $last_index; $index++) {
        push @new, [$array->@[$index .. ($index + $length)]];
    }
    return bless(\@new, 'Array');
}

sub intersperse($array, $value) {
    return empty('Array')               if @$array == 0;
    return bless([$array->[0]],'Array') if @$array == 1;

    my @new   = $array->[0];
    my $index = 1;
    my $emit  = 1;

    while (1) {
        last if $index >= @$array;
        if ( $emit ) {
            push @new, $value;
            $emit = 0;
        }
        else {
            push @new, $array->[$index++];
            $emit = 1;
        }
    }

    return bless(\@new, 'Array');
}

sub repeat($array, $count) {
    return empty('Array') if $count <= 0;
    return bless([(@$array) x $count], 'Array');
}

sub take_while($array, $predicate) {
    my @new;
    for my $x ( @$array ) {
        last if not $predicate->($x);
        push @new, $x;
    }
    return bless(\@new, 'Array');
}

sub skip_while($array, $predicate) {
    my $index = 0;
    for my $x ( @$array ) {
        last if not $predicate->($x);
        $index++;
    }
    return bless([$array->@[$index .. $array->$#*]], 'Array');
}

#-----------------------------------------------------------------------------#
# SIDE-EFFECTS                                                                #
#    functions that have side-effects or produce side-effects. Those are      #
#    immediately executed, usually consuming all elements of Seq at once.     #
#-----------------------------------------------------------------------------#

sub iter($array, $f) {
    for my $x ( @$array ) {
        $f->($x);
    }
    return;
}

sub iteri($array, $f) {
    for (my $i=0; $i < @$array; $i++) {
        $f->($array->[$i], $i);
    }
    return;
}

sub foreach($array, $f) {
    iter($array, $f);
}

sub foreachi($array, $f) {
    iteri($array, $f);
}

#-----------------------------------------------------------------------------#
# CONVERTER                                                                   #
#         Those are functions converting Array to none Array types            #
#-----------------------------------------------------------------------------#

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
    return CORE::join($sep, @$array);
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

sub find($array, $default, $predicate) {
    for my $x ( @$array ) {
        return $x if $predicate->($x);
    }
    return $default;
}

sub any($array, $predicate) {
    for my $x ( @$array ) {
        return 1 if $predicate->($x);
    }
    return 0;
}

sub all($array, $predicate) {
    for my $x ( @$array ) {
        return 0 if not $predicate->($x);
    }
    return 1;
}

sub none($array, $predicate) {
    for my $x ( @$array ) {
        return 0 if $predicate->($x);
    }
    return 1;
}

sub pick($array, $default, $map) {
    for my $x ( @$array ) {
        my $value = $map->($x);
        return $value if defined $value;
    }
    return $default;
}

1;