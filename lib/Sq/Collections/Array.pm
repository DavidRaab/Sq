package Array;
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort', 'map', 'foreach', 'bless', 'length';
use Scalar::Util ();
use List::Util ();
use Carp ();

#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create sequences                          #
#-----------------------------------------------------------------------------#

sub empty($class) {
    return CORE::bless([], 'Array');
}

sub replicate($class, $count, $initial) {
    return CORE::bless([($initial) x $count], 'Array');
}

# creates new array, stops at first undef
sub new($class, @array) {
    my @copy;
    for my $x ( @array ) {
        last if not defined $x;
        push @copy, $x;
    }
    return CORE::bless(\@copy, 'Array');
}

# wraps all function arguments into Array. Stops at first undef
sub wrap {
    return new(@_);
}

sub bless($class, $ref) {
    if ( ref $ref eq 'ARRAY' ) {
        return CORE::bless($ref, 'Array');
    }
    else {
        Carp::croak('Array->bless($aref) must be called with arrayref.');
    }
}

# Array->from_array : Array<'a> -> Array<'a>
sub from_array($class, $xs) {
    return CORE::bless($xs, 'Array');
}

sub concat($class, @arrays) {
    my @new;
    for my $array ( @arrays ) {
        push @new, @$array;
    }
    return CORE::bless(\@new, 'Array');
}

sub init($class, $count, $f) {
    local $_;
    return CORE::bless([
        grep { defined  }
        map  { $f->($_) }
            0 .. ($count-1)
    ], 'Array');
}

# Array->unfold : 'State -> ('State -> Option<['a, 'State]>) -> Array<'a>
sub unfold($, $state, $f_opt) {
    my @array;

    my ($is_some, $x);
    while (1) {
        ($is_some, $x, $state) = Option->extract_array($f_opt->($state));
        last if !$is_some;
        push @array, $x;
    }

    return CORE::bless(\@array, 'Array');
}

# Array->range_step : float -> float -> float -> Array<float>
sub range_step($, $start, $step, $stop) {
    Carp::croak '$step is 0. Will run forever.' if $step == 0;
    return CORE::bless([$start], 'Array') if $start == $stop;

    # Ascending Order
    my @new;
    if ( $start < $stop ) {
        my $current = $start;
        while (1) {
            push @new, $current;
            $current += $step;
            last if $current > $stop;
        }
    }
    # Descending Order
    else {
        my $current = $start;
        while (1) {
            push @new, $current;
            $current -= $step;
            last if $current < $stop;
        }
    }
    return CORE::bless(\@new, 'Array');
}

# Array->range : int -> int -> Array<int>
sub range($, $start, $stop) {
    $start = int $start;
    $stop  = int $stop;
    return CORE::bless([$start], 'Array') if $start == $stop;

    my @new;
    # Ascending
    if ( $start < $stop ) {
        my $current = $start;
        while (1) {
            push @new, $current++;
            last if $current > $stop;
        }
    }
    # Descending
    else {
        my $current = $start;
        while (1) {
            push @new, $current--;
            last if $current < $stop;
        }
    }
    return CORE::bless(\@new, 'Array');
}

#-----------------------------------------------------------------------------#
# METHODS                                                                     #
#           functions operating on Array and returning another Array          #
#-----------------------------------------------------------------------------#

sub copy($array) {
    my @new;
    for my $x ( @$array ) {
        last if not defined $x;
        push @new, $x;
    }
    return CORE::bless(\@new, 'Array');
}

sub bind($array, $f) {
    my @new;
    for my $x ( @$array ) {
        push @new, @{ $f->($x) };
    }
    return CORE::bless(\@new, 'Array');
}

sub flatten($array) {
    return bind($array, \&Sq::id);
}

sub cartesian($as, $bs) {
    my $new = new('Array');
    for my $a ( @$as ) {
        for my $b ( @$bs ) {
            push @$new, CORE::bless([$a, $b], 'Array');
        }
    }
    return $new;
}

# append : Array<'a> -> Array<'a> -> Array<'a>
sub append($array1, $array2) {
    return CORE::bless([@$array1, @$array2], 'Array');
}

# rev : Array<'a> -> Array<'a>
sub rev($array) {
    return CORE::bless([reverse @$array], 'Array');
}

# map : Array<'a> -> ('a -> 'b) -> Array<'b>
sub map($array, $f) {
    return CORE::bless([
        grep { defined  }
        map  { $f->($_) } @$array
    ], 'Array');
}

sub map_e($array, $expr) {
    my $new = eval "[grep { defined } map { $expr } \@\$array]";
    return CORE::bless($new, 'Array');
}

sub choose($array, $f_opt) {
    my $new = new('Array');
    my ($is_some, $v);
    for my $x ( @$array ) {
        ($is_some, $v) = Option->extract($f_opt->($x));
        push @$new, $v if $is_some;
    }
    return $new;
}

sub mapi($array, $f) {
    my @new;
    my $idx = 0;
    for my $x ( @$array ) {
        my $value = $f->($x, $idx++);
        push @new, $value if defined $value;
    }
    return CORE::bless(\@new, 'Array');
}

# filter : Array<'a> -> ('a -> bool) -> Array<'a>
sub filter($array, $predicate) {
    local $_;
    return CORE::bless([grep { $predicate->($_) } @$array], 'Array');
}

# same as filter but expects a string-code
sub filter_e($array, $expr) {
    local $_;
    my $data = eval "[grep { $expr } \@\$array]";
    return CORE::bless($data, 'Array');
}

sub skip($array, $amount) {
    return CORE::bless([@$array], 'Array') if $amount <= 0;
    return CORE::bless([$array->@[$amount .. $array->$#*]], 'Array');
}

# take : Array<'a> -> Array<'a>
sub take($array, $amount) {
    my @array;
    for (my $idx=0; $idx < $amount; $idx++ ) {
        my $x = $array->[$idx];
        last if !defined $x;
        push @array, $x;
    }
    return CORE::bless(\@array, 'Array');
}

# adds index to an array
sub indexed($array) {
    my $idx = 0;
    my @new;
    for my $x ( @$array ) {
        push @new, [$x, $idx++];
    }
    return CORE::bless(\@new, 'Array');
}

# zip : Array<'a> -> Array<'b> -> Array<'a * 'b>
sub zip($array1, $array2) {
    my @new;
    my $idx = 0;
    while (1) {
        my $x = $array1->[$idx];
        my $y = $array2->[$idx];
        last if !defined($x) or !defined($y);
        push @new, CORE::bless([$x,$y], 'Array');
        $idx++;
    }
    return CORE::bless(\@new, 'Array');
}

sub sort($array, $comparer) {
    local ($a, $b);
    my @sorted = CORE::sort { $comparer->($a, $b) } @$array;
    return CORE::bless(\@sorted, 'Array');
}

sub sort_by($array, $comparer, $f_key) {
    local ($a, $b, $_);
    my @sorted =
        CORE::map  { $_->[1] }
        CORE::sort { $comparer->($a->[0], $b->[0]) }
        CORE::map  { [$f_key->($_), $_] }
            @$array;
    return CORE::bless(\@sorted, 'Array');
}

sub sort_num($array) {
    return CORE::bless([sort { $a <=> $b } @$array], 'Array');
}

sub sort_str($array) {
    return CORE::bless([sort { $a cmp $b } @$array], 'Array');
}

# Array<Hash<'Key,'a>> -> 'Key -> Array<Hash<'Key,'a>>
sub sort_hash_str($array, $key) {
    return Array::sort($array, sub($x,$y) {
        $x->{$key} cmp $y->{$key}
    });
}

# Sorts an array of hashes by just providing the key to be used. Keys
# are number compared.
#
# Array<Hash<'Key,'a>> -> 'Key -> Array<Hash<'Key,'a>>
sub sort_hash_num($array, $key) {
    return Array::sort($array, sub($x,$y) {
        $x->{$key} <=> $y->{$key}
    });
}

sub fsts($array) {
    my @new;
    for my $x ( @$array ) {
        push @new, $x->[0];
    }
    return CORE::bless(\@new, 'Array');
}

sub snds($array) {
    my @new;
    for my $x ( @$array ) {
        push @new, $x->[1];
    }
    return CORE::bless(\@new, 'Array');
}

sub to_array($array, $count=undef) {
    $count = Sq::is_num($count) ? int($count) : undef;
    if ( defined $count && $count < @$array ) {
        my $new     = new('Array');
        my $current = 0;
        for my $idx ( 0 .. $count-1 ) {
            push @$new, $array->[$idx];
        }
        return $new;
    }
    else {
        return $array;
    }
}

# Does nothing. It is just here for API compatibility with Seq::to_array_of_array
sub to_array_of_array($array_of_array) {
    return $array_of_array;
}

# Array<'a> -> Array<'a>
sub distinct($array) {
    my %seen;
    my @new;
    for my $value ( @$array ) {
        if ( not exists $seen{$value} ) {
            push @new, $value;
            $seen{$value} = 1;
        }
    }
    return CORE::bless(\@new, 'Array');
}

# Only returns distinct values of an array. Distinct is decided by the
# $get_key function that must return a unique string for deciding uniqueness
#
# Array<'a> -> ('a -> string) -> Array<'a>
sub distinct_by($array, $f_str) {
    my %seen;
    my @new;
    for my $value ( @$array ) {
        my $str = $f_str->($value);
        if ( not exists $seen{$str} ) {
            push @new, $value;
            $seen{$str} = 1;
        }
    }
    return CORE::bless(\@new, 'Array');
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
    return CORE::bless(\@new, 'Array');
}

sub windowed($array, $window_size) {
    return empty('Array') if $window_size <= 0;

    my $length     = $window_size - 1;
    my $last_index = @$array - $length;
    my @new;
    for (my $index=0; $index < $last_index; $index++) {
        push @new, [$array->@[$index .. ($index + $length)]];
    }
    return CORE::bless(\@new, 'Array');
}

sub intersperse($array, $value) {
    return empty('Array')                     if @$array == 0;
    return CORE::bless([$array->[0]],'Array') if @$array == 1;

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

    return CORE::bless(\@new, 'Array');
}

sub repeat($array, $count) {
    return empty('Array') if $count <= 0;
    return CORE::bless([(@$array) x $count], 'Array');
}

sub take_while($array, $predicate) {
    my @new;
    for my $x ( @$array ) {
        last if not $predicate->($x);
        push @new, $x;
    }
    return CORE::bless(\@new, 'Array');
}

sub skip_while($array, $predicate) {
    my $index = 0;
    for my $x ( @$array ) {
        last if not $predicate->($x);
        $index++;
    }
    return CORE::bless([$array->@[$index .. $array->$#*]], 'Array');
}

sub slice($array, @idxs) {
    my $max = @$array;
    my $min = (-$max) - 1;
    return CORE::bless([$array->@[grep {$_ < $max && $_ > $min} @idxs]], 'Array');
}

sub extract($array, $pos, $length) {
    return CORE::bless([], 'Array') if $length <= 0;
    return CORE::bless([], 'Array') if $pos > @$array;

    my $start = $pos < 0 ? @$array + $pos : $pos;
    my $end   = $start+$length < @$array ? $start+$length : @$array;
    my $new = new('Array');
    for (my $idx=$start; $idx < $end; $idx++) {
        push @$new, $array->[$idx];
    }
    return $new;
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

# fold : Array<'a> -> 'State -> (a -> 'State -> 'State) -> 'State
sub fold($array, $state, $folder) {
    for my $x ( @$array ) {
        $state = $folder->($x,$state);
    }
    return $state;
}

# fold : Array<'a> -> 'State -> ('State -> 'a -> 'State) -> 'State
sub fold_mut($array, $state, $folder) {
    for my $x ( @$array ) {
        $folder->($x,$state);
    }
    return $state;
}

sub reduce($array, $f) {
    return Option::None()            if @$array == 0;
    return Option::Some($array->[0]) if @$array == 1;
    my $init = $array->[0];
    for (my $idx=1; $idx < @$array; $idx++) {
        $init = $f->($init, $array->[$idx]);
    }
    return Option::Some($init);
}

# length : Array<'a> -> int
sub length($array) {
    return scalar @{ $array };
}

sub expand($array) {
    return @$array;
}

sub first($array) {
    return Option::Some($array->[0]);
}

sub last($array) {
    return Option::Some($array->[-1]);
}

sub sum($array) {
    my $sum = 0;
    for my $x ( @$array ) {
        $sum += $x;
    }
    return $sum;
}

sub sum_by($array, $f_map) {
    my $sum = 0;
    for my $x ( @$array ) {
        $sum += $f_map->($x);
    }
    return $sum;
}

sub join($array, $sep) {
    return CORE::join($sep, @$array);
}

sub split($array, $regex) {
    CORE::bless([
        map { CORE::bless([split $regex, $_], 'Array') } @$array
    ], 'Array');
}

# min : Array<float> -> float -> Option<float>
sub min($array) {
    return Option::None() if @$array == 0;
    my $min = $array->[0];
    for my $x ( @$array ) {
        $min = $x if $x < $min;
    }
    return Option::Some($min);
}

# min_by : Array<'a> -> ('a -> float) -> Option<'a>
sub min_by($array, $f_number) {
    my $min     = undef;
    my $min_key = undef;
    for my $x ( @$array ) {
        my $key = $f_number->($x);
        if ( defined $min ) {
            if ( $key < $min_key ) {
                $min     = $x;
                $min_key = $key;
            }
        }
        else {
            $min     = $x;
            $min_key = $key;
        }
    }
    return Option::Some($min);
}

# min_str : Seq<string> -> string -> Option<string>
sub min_str($array) {
    min_str_by($array, \&Sq::id);
}

# min_str_by : Seq<'a> -> ('a -> string) -> Option<'a>
sub min_str_by($array, $f_str) {
    my $min     = undef;
    my $min_key = undef;
    for my $x ( @$array ) {
        my $key = $f_str->($x);
        if ( defined $min ) {
            if ( $key lt $min_key ) {
                $min     = $x;
                $min_key = $key;
            }
        }
        else {
            $min     = $x;
            $min_key = $key;
        }
    }
    return Option::Some($min);
}

# max : Array<float> -> Option<float>
sub max($array) {
    return Option::None() if @$array == 0;
    my $max = $array->[0];
    for my $x ( @$array ) {
        $max = $x if $x > $max;
    }
    return Option::Some($max);
}

# max_by : Array<'a> -> ('a -> float) -> Option<'a>
sub max_by($array, $f_number) {
    my $max     = undef;
    my $max_key = undef;
    for my $x ( @$array ) {
        my $key = $f_number->($x);
        if ( defined $max ) {
            if ( $key > $max_key ) {
                $max     = $x;
                $max_key = $key;
            }
        }
        else {
            $max     = $x;
            $max_key = $key;
        }
    }
    return Option::Some($max);
}

# max_str : Array<string> -> string
sub max_str($array) {
    max_str_by($array, \&Sq::id);
}

# max_str_by : Array<'a> -> ('a -> string) -> Option<'a>
sub max_str_by($array, $f_str) {
    my $max     = undef;
    my $max_key = undef;
    for my $x ( @$array ) {
        my $key = $f_str->($x);
        if ( defined $max ) {
            if ( $key gt $max_key ) {
                $max     = $x;
                $max_key = $key;
            }
        }
        else {
            $max     = $x;
            $max_key = $key;
        }
    }
    return Option::Some($max);
}

# Combines grouping and folding in one operation. All elements of a sequence
# are grouped together by a key. The $folder function than can combine
# multiple elements of the same key. For the first element found for a
# key the $get_state function is called to produce the initial value, otherwise
# the existing value is used. Returns a Hash with the 'Key to 'State
# mapping.
#
# Array<'a>
# -> (unit -> 'State)
# -> ('a -> 'Key)
# -> ('State -> 'a -> 'State)
# -> Hash<'key, 'State>
sub group_fold($array, $f_init, $f_key, $f_state) {
    my $new = Hash->new;
    for my $x ( @$array ) {
        my $key = $f_key->($x);
        if ( exists $new->{$key} ) {
            $new->{$key} = $f_state->($new->{$key}, $x);
        }
        else {
            $new->{$key} = $f_state->($f_init->(), $x);
        }
    }
    return $new;
}

# Array<'a> -> ('a -> ('Key,'Value)) -> Hash<'Key, 'Value>
sub to_hash($array, $f_map) {
    my %hash;
    for my $x ( @$array ) {
        my ($key, $value) = $f_map->($x);
        $hash{$key} = $value;
    }
    return CORE::bless(\%hash, 'Hash');
}

# Array<'a> -> ('a -> ('Key,'Value)) -> Hash<'Key, Array<'Value>>
sub to_hash_of_array($array, $f_map) {
    my $hash = Hash->new;
    for my $x ( @$array ) {
        my ($key, $value) = $f_map->($x);
        $hash->push($key, $value);
    }
    return $hash;
}

# Array -> Hash<'Key,'Value>
sub as_hash($array) {
    return CORE::bless({ @$array }, 'Hash');
}

# Array<'a> -> ('a -> 'Key) -> Hash<'Key, 'a>
sub keyed_by($array, $f_key) {
    my %hash;
    for my $x ( @$array ) {
        $hash{$f_key->($x)} = $x;
    }
    return CORE::bless(\%hash, 'Hash');
}

# Like `keyed_by` but instead of overriding it gathers an Array of all values
# with the same 'Key.
#
# Array<'a> -> ('a -> 'Key) -> Hash<'Key, Array<'a>>
sub group_by($array, $f_key) {
    my $hash = Hash->new;
    for my $x ( @$array ) {
        my $key = $f_key->($x);
        $hash->push($key, $x);
    }
    return $hash;
}

# Array<'a> -> Hash<'a,int>
sub count($array) {
    my $new = Hash->new;
    for my $key ( @$array ) {
        $new->{$key}++;
    }
    return $new;
}

sub count_by($array, $f_key) {
    my $new = Hash->new;
    for my $x ( @$array ) {
        $new->{$f_key->($x)}++;
    }
    return $new;
}

sub find($array, $predicate) {
    for my $x ( @$array ) {
        return Option::Some($x) if $predicate->($x);
    }
    return Option::None();
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

sub pick($array, $f_opt) {
    for my $x ( @$array ) {
        my $opt = Option::Some($f_opt->($x));
        return $opt if @$opt;
    }
    return Option::None();
}

# to_seq: Array<'a> -> Seq<'a>
sub to_seq($array) {
    return Seq->from_array($array);
}

sub dump($array, $inline=60, $depth=0) {
    state $quote = sub($str) {
        $str =~ s/\r/\\r/;
        $str =~ s/\n/\\n/;
        $str =~ s/\t/\\t/;
        $str;
    };
    state $compact = sub($max, $str) {
        # replace empty string/array
        return '[]' if $str =~ m/\A\s*\[\s*\]\z/;
        return '{}' if $str =~ m/\A\s*\{\s*\}\z/;

        # get indentation length
        my $indent = $str =~ m/\A(\s+)/ ? CORE::length $1 : 0;

        # remove whitespace at start/end and replace all whitespace with
        # a single space
        my $no_ws = $str;
        $no_ws =~ s/\A\s+//;
        $no_ws =~ s/\s+\z//;
        $no_ws =~ s/\s+/ /g;

        # when $no_ws is smaller than $max we keep that string but we
        # need to add $ident again
        if ( CORE::length $no_ws <= $max ) {
            $str = (" " x $indent) . $no_ws;
        }

        return $str;
    };

    my $str = "[\n";
    for my $x ( @$array ) {
        my $indent = " " x ($depth + 2);
        my $type   = ref $x;
        if ( !defined $x ) {
            $str .= $indent . 'undef' . ",\n";
        }
        elsif ( Sq::is_num($x) ) {
            $str .= $indent . $x . ",\n";
        }
        elsif ( Sq::is_str($x) ) {
            $str .= $indent . sprintf "\"%s\",\n", $quote->($x);
        }
        elsif ( $type eq 'Option' ) {
            $str .= $indent . $compact->($inline, Option::dump($x, $inline, $depth+2)) . ",\n";
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            $str .= $indent . $compact->($inline, Hash::dump($x, $inline, $depth+2)) . ",\n";
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            $str .= $indent . $compact->($inline, Array::dump($x, $inline, $depth+2)) . ",\n";
        }
        else {
            $str .= $indent . "NOT_IMPLEMENTED,\n";
        }
    }
    $str =~ s/,\n\z/\n/;
    $str .= (" " x $depth) . "]";
    return $compact->($inline, $str);
}

#-----------------------------------------------------------------------------#
# MUTATION                                                                    #
#         Those are functions mutating an array                               #
#-----------------------------------------------------------------------------#

sub push($array, @values) {
    for my $x ( @values ) {
        return if !defined $x;
        CORE::push(@$array, $x);
    }
    return;
}

sub pop($array) {
    return CORE::pop @$array;
}

sub shift($array) {
    return CORE::shift @$array;
}

sub unshift($array, @values) {
    # we need to built a new array, otherwise typical unshift order
    # is not preserved
    my @unshift;
    for my $x ( @values ) {
        last if !defined $x;
        CORE::push @unshift, $x;
    }
    CORE::unshift @$array, @unshift;
    return;
}

sub blit($source_array, $source_index, $target_array, $target_index, $amount) {
    # allow negative indexing
    $source_index =
        $source_index < 0
        ? @$source_array + $source_index
        : $source_index;

    # allows negativ indexing
    $target_index =
        $target_index < 0
        ? @$target_array + $target_index
        : $target_index;

    # copy only as much values as available in source
    my $max_amount = @$source_array - $source_index;
    $amount = $amount < $max_amount ? $amount : $max_amount;

    # actual copying
    for ( 1 .. $amount ) {
        $target_array->[$target_index] = $source_array->[$source_index];
        $source_index++;
        $target_index++;
    }
    return;
}

sub shuffle($array) {
    my $max = @$array;
    my $new_idx;
    for ( my $idx=0; $idx < ($max-1); $idx++ ) {
        $new_idx = rand($max);
        my $tmp = $array->[$idx];
        $array->[$idx]     = $array->[$new_idx];
        $array->[$new_idx] = $tmp;
    }
    return;
}

1;