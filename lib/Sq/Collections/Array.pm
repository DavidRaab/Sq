package Sq::Collections::Array;
package Array;
use List::Util ();
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort', 'map', 'foreach', 'bless', 'length';

#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create sequences                          #
#-----------------------------------------------------------------------------#

sub empty($) {
    return CORE::bless([], 'Array');
}

sub replicate($, $count, $initial) {
    return CORE::bless([($initial) x $count], 'Array');
}

# creates new array, stops at first undef
sub new($, @array) {
    my @new;
    for my $x ( @array ) {
        last if not defined $x;
        push @new, $x;
    }
    return CORE::bless(\@new, 'Array');
}

sub bless($, $ref) {
    return CORE::bless($ref, 'Array');
}

# Array->from_array : Array<'a> -> Array<'a>
sub from_array($, $xs) {
    return CORE::bless($xs, 'Array');
}

sub concat($, @arrays) {
    my @new;
    for my $array ( @arrays ) {
        push @new, @$array;
    }
    return CORE::bless(\@new, 'Array');
}

sub init($, $count, $f) {
    local $_;
    return CORE::bless([
        grep { defined  }
        map  { $f->($_) }
            0 .. ($count-1)
    ], 'Array');
}

sub init2d($, $width, $height, $f) {
    my @new;
    for my $y ( 0 .. $height-1 ) {
        my @inner;
        for my $x ( 0 .. $width-1 ) {
            push @inner, (scalar $f->($x,$y));
        }
        push @new, CORE::bless(\@inner, 'Array');
    }
    return CORE::bless(\@new, 'Array');
}

# Array->unfold : 'State -> ('State -> Option<['a, 'State]>) -> Array<'a>
sub unfold($, $state, $f_opt) {
    my @array;

    my ($is_some, $x);
    while (1) {
        ($is_some, $x, $state) = Option->extract($f_opt->($state));
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

sub flatten($array_of_array) {
    return bind($array_of_array, \&Sq::id);
}

# create merge as alias to flatten
{
    no warnings 'once';
    *merge = \&flatten;
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
# for_defined
sub map($array, $f) {
    local $_;
    my (@new, $value);
    for ( @$array ) {
        $value = $f->($_);
        last if !defined $value;
        CORE::push @new, $value;
    }
    return CORE::bless(\@new, 'Array');
}

sub map_e($array, $expr) {
    local $_;
    my $new = eval q<
        my (@new, $value);
        for ( @$array ) {
            $value = > . $expr . q<;
            last if !defined $value;
            CORE::push @new, $value;
        }
        return \@new;
    >;
    Carp::croak $@ if !defined $new;
    return CORE::bless($new, 'Array');
}

sub chunked($array, $size) {
    my @new;
    my $max  = @$array;
    my $upto = 0;
    for (my $idx=0; $idx < $max; $idx+=$size) {
        $upto     = ($idx + $size) - 1;
        $upto     = $upto < $max ? $upto : ($max-1);
        my @slice = $array->@[$idx .. $upto];
        push @new, CORE::bless(\@slice, 'Array');
    }
    return CORE::bless(\@new, 'Array');
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
    local $_;
    my (@new, $value);
    my $idx = 0;
    for ( @$array ) {
        $value = $f->($_, $idx++);
        last if !defined $value;
        push @new, $value;
    }
    return CORE::bless(\@new, 'Array');
}

# TODO: Remove in future
sub filter   { Carp::croak "Array::filter renamed to Array::keep"     }
sub filter_e { Carp::croak "Array::filter_e renamed to Array::keep_e" }

# keep : Array<'a> -> ('a -> bool) -> Array<'a>
sub keep($array, $predicate) {
    local $_;
    return CORE::bless([grep { $predicate->($_) } @$array], 'Array');
}

sub keep_some($array_of_opt) {
    my @new;
    for my $opt ( @$array_of_opt ) {
        push @new, @$opt if @$opt;
    }
    return CORE::bless(\@new, 'Array');
}

sub keep_some_by($array, $f) {
    my @new;
    for my $x ( @$array ) {
        my $opt = $f->($x);
        push @new, @$opt if @$opt;
    }
    return CORE::bless(\@new, 'Array');
}

sub keep_type($array, $type) {
    my @new;
    for my $x ( @$array ) {
        if ( Sq::Type::t_valid($type, $x) ) {
            push @new, $x;
        }
    }
    return CORE::bless(\@new, 'Array');
}

# same as keep but expects a string-code
sub keep_e($array, $expr) {
    local $_;
    my $data = eval "[grep { $expr } \@\$array]";
    Carp::croak $@ if !defined $data;
    return CORE::bless($data, 'Array');
}

sub remove($array, $predicate) {
    local $_;
    return CORE::bless([grep { !$predicate->($_) } @$array], 'Array');
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

sub zip(@arrays) {
    my @new;
    my $idx = 0;
    INNER:
    while (1) {
        my (@inner, $x);
        for my $array ( @arrays ) {
            $x = $array->[$idx];
            last INNER if !defined $x;
            push @inner, $x;
        }
        push @new, CORE::bless(\@inner, 'Array');
        $idx++;
    }
    return CORE::bless(\@new, 'Array');
}

sub fill2d($aoa, $f) {
    my $maxX = 0;
    for my $array ( @$aoa ) {
        my $l = @$array;
        $maxX = $l > $maxX ? $l : $maxX;
    }

    my @new;
    for my $array ( @$aoa ) {
        my @inner;
        for (my $x=0; $x < $maxX; $x++) {
            my $value = $array->[$x];
            if ( defined $value ) {
                push @inner, $value;
            }
            else {
                push @inner, $f->();
            }
        }
        push @new, CORE::bless(\@inner, 'Array');
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
        CORE::map  { $_->[0] }
        CORE::sort { $comparer->($a->[1], $b->[1]) }
        CORE::map  { [$_, $f_key->($_)] }
            @$array;
    return CORE::bless(\@sorted, 'Array');
}

# Array<Hash<'Key,'a>> -> 'Key -> Array<Hash<'Key,'a>>
sub sort_hash($array, $comparer, $key) {
    local ($a, $b);
    my @sorted =
        CORE::map  { $_->[0]                       }
        CORE::sort { $comparer->($a->[1], $b->[1]) }
        CORE::map  { [$_, $_->{$key}]              }
            @$array;
    return CORE::bless(\@sorted, 'Array');
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

sub rx($array, $regex) {
    my @new;
    for my $str ( @$array ) {
        push @new, $str if $str =~ $regex;
    }
    return CORE::bless(\@new, 'Array');
}

sub rxm($array, $regex) {
    my @new;
    for my $str ( @$array ) {
        if ( $str =~ $regex ) {
            push @new, CORE::bless([@{^CAPTURE}], 'Array');
        }
    }
    return CORE::bless(\@new, 'Array');
}

sub rxs($array, $regex, $f) {
    my @new;
    for my $str ( @$array ) {
        push @new, $str =~ s/$regex/$f->()/re;
    }
    return CORE::bless(\@new, 'Array');
}

sub rxsg($array, $regex, $f) {
    my @new;
    for my $str ( @$array ) {
        push @new, $str =~ s/$regex/$f->()/gre;
    }
    return CORE::bless(\@new, 'Array');
}

sub windowed($array, $window_size) {
    return empty('Array') if $window_size <= 0;

    my $length     = $window_size - 1;
    my $last_index = @$array - $length;
    my @new;
    for (my $index=0; $index < $last_index; $index++) {
        push @new, CORE::bless([$array->@[$index .. ($index + $length)]], 'Array');
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

# TODO: Other name
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

sub diff($arrayA, $arrayB, $f_key) {
    my @new;
    my %indexB = map { $f_key->($_) => 1 } @$arrayB;
    my $key;
    for my $value ( @$arrayA ) {
        $key = $f_key->($value);
        if ( !exists $indexB{$key} ) {
            push @new, $value;
        }
    }
    return CORE::bless(\@new, 'Array');
}

sub shuffle($array) {
    return CORE::bless([List::Util::shuffle @$array], 'Array');
}

sub trim($array) {
    my @new;
    for ( @$array ) {
        my $str = $_;
        $str =~ s/\A\s+//;
        $str =~ s/\s+\z//;
        push @new, $str;
    }
    return CORE::bless(\@new, 'Array');
}

sub transpose($aoa) {
    return Array::zip(@$aoa);
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

sub iter2d($aoa, $f) {
    for my $y ( 0 .. (@$aoa - 1) ) {
        my $inner = $aoa->[$y];
        for my $x ( 0 .. (@$inner - 1) ) {
            $f->($inner->[$x],$x,$y);
        }
    }
    return;
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
sub min_by($array, $f_num) {
    return Option::None() if @$array == 0;
    my $min     = $array->[0];
    my $min_num = $f_num->($min);
    my ($x, $num);
    for my $x ( @$array ) {
        $num = $f_num->($x);
        if ( $num < $min_num ) {
            $min     = $x;
            $min_num = $num;
        }
    }
    return Option::Some($min);
}

# min_str : Seq<string> -> string -> Option<string>
sub min_str($array) {
    return Option::None() if @$array == 0;
    my $min = $array->[0];
    my $x;
    for my $x ( @$array ) {
        $min = $x if $x lt $min;
    }
    return Option::Some($min);
}

# min_str_by : Seq<'a> -> ('a -> string) -> Option<'a>
sub min_str_by($array, $f_str) {
    return Option::None() if @$array == 0;
    my $min     = $array->[0];
    my $min_str = $f_str->($min);
    my ($x, $str);
    for my $x ( @$array ) {
        $str = $f_str->($x);
        if ( $str lt $min_str ) {
            $min     = $x;
            $min_str = $str;
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
sub max_by($array, $f_num) {
    return Option::None() if @$array == 0;
    my $max     = $array->[0];
    my $max_num = $f_num->($max);
    my ($x, $num);
    for my $x ( @$array ) {
        $num = $f_num->($x);
        if ( $num > $max_num ) {
            $max     = $x;
            $max_num = $num;
        }
    }
    return Option::Some($max);
}

# max_str : Array<string> -> string
sub max_str($array) {
    return Option::None() if @$array == 0;
    my $max = $array->[0];
    my $x;
    for my $x ( @$array ) {
        $max = $x if $x gt $max;
    }
    return Option::Some($max);
}

# max_str_by : Array<'a> -> ('a -> string) -> Option<'a>
sub max_str_by($array, $f_str) {
    return Option::None() if @$array == 0;
    my $max     = $array->[0];
    my $max_str = $f_str->($max);
    my ($x, $str);
    for my $x ( @$array ) {
        $str = $f_str->($x);
        if ( $str gt $max_str ) {
            $max     = $x;
            $max_str = $str;
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
sub group_fold($array, $f_init, $f_str, $f_state) {
    my $new = Hash->new;
    for my $x ( @$array ) {
        my $str = $f_str->($x);
        if ( exists $new->{$str} ) {
            $new->{$str} = $f_state->($new->{$str}, $x);
        }
        else {
            $new->{$str} = $f_state->($f_init->(), $x);
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
sub keyed_by($array, $f_str) {
    my %hash;
    for my $x ( @$array ) {
        $hash{$f_str->($x)} = $x;
    }
    return CORE::bless(\%hash, 'Hash');
}

# Like `keyed_by` but instead of overriding it gathers an Array of all values
# with the same 'Key.
#
# Array<'a> -> ('a -> 'Key) -> Hash<'Key, Array<'a>>
sub group_by($array, $f_str) {
    my $hash = Hash->new;
    for my $x ( @$array ) {
        my $str = $f_str->($x);
        $hash->push($str, $x);
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

sub count_by($array, $f_str) {
    my $new = Hash->new;
    for my $x ( @$array ) {
        $new->{$f_str->($x)}++;
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

sub all_some($array_of_opt) {
    my $new = new 'Array';
    for my $opt ( @$array_of_opt ) {
        if ( @$opt ) { push @$new, @$opt               }
        else         { return CORE::bless([],'Option') }
    }
    return CORE::bless([$new], 'Option');
}

sub all_some_by($array, $f) {
    my $new = new 'Array';
    for my $x ( @$array ) {
        my $opt = $f->($x);
        if ( @$opt ) { push @$new, @$opt               }
        else         { return CORE::bless([],'Option') }
    }
    return CORE::bless([$new], 'Option');
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

sub shuffle_mut($array) {
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