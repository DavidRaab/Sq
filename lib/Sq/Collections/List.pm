package List;
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort', 'map';
use Scalar::Util ();
use List::Util ();
use Carp ();
use Sq::Collections::Array;

#-----------------------------------------------------------------------------#
# BASICS                                                                      #
#           Basic functions that form the List Data-Structure                 #
#-----------------------------------------------------------------------------#

sub empty($class)              { bless([],             'List') }
sub cons($class, $head, $tail) { bless([$head, $tail], 'List') }
sub head($list)                { $list->[0]                    }
sub tail($list)                { $list->[1]                    }

sub is_empty($list) {
    return 1 if Scalar::Util::reftype $list eq 'ARRAY' && @$list == 0;
    return 0;
}

# This is a special function that allows to constructs List in a mutable
# way. You are supposed to pass it an empty cell (end of list) and an $x.
# It will add $x to the end of the list, create a new empty and return it.
my $mut_append = sub($list, $x) {
    my $new    = bless([], 'List');
    $list->[0] = $x;
    $list->[1] = $new;
    return $new;
};

#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create lists                              #
#-----------------------------------------------------------------------------#

# List->unfold : 'State -> ('State -> Option<ListContext<'a, 'State>>) -> List<'a>
sub unfold($class, $state, $f) {
    my $s    = $state;
    my $new  = empty('List');
    my $tail = $new;

    my $x;
    while (1) {
        ($x, $s) = $f->($s);
        return $new if not defined($x);
        $tail = $mut_append->($tail, $x);
    }
}

sub wrap($class, @xs) {
    my $count = @xs;
    return unfold('List', 0, sub($i) {
        my $x = $xs[$i];
        return undef if $i >= $count || (not defined $x);
        return $x, $i+1;
    });
}

sub init($class, $amount, $gen) {
    return unfold('List', 0, sub($idx) {
        return undef if $idx >= $amount;
        return $gen->($idx), $idx+1;
    });
}

# List->range_step : float -> float -> float -> Array<float>
sub range_step($class, $start, $step, $stop) {
    Carp::croak '$step is 0. Will run forever.' if $step == 0;

    # Ascending Order
    if ( $start <= $stop ) {
        return unfold('List', $start, sub($current) {
            return $current, $current+$step if $current <= $stop;
            return undef;
        });
    }
    # Descending Order
    else {
        return unfold('List', $start, sub($current) {
            return $current, $current-$step if $current >= $stop;
            return undef;
        });
    }
}

# List->range : float -> float -> Array<float>
sub range($class, $start, $stop) {
    return range_step('List', $start, 1, $stop);
}

sub concat($class, @lists) {
    my $new  = empty('List');
    my $tail = $new;

    for my $list ( @lists ) {
        iter($list, sub($x) {
            $tail = $mut_append->($tail, $x);
        });
    }

    return $new;
}

sub from_array($class, $array) {
    my $new  = empty('List');
    my $tail = $new;

    for my $x ( @$array ) {
        $tail = $mut_append->($tail, $x);
    }

    return $new;
}

sub replicate($class, $count, $value) {
    my $new  = empty('List');
    my $tail = $new;

    for ( 1 .. $count ) {

        $tail = $mut_append->($tail, $value);
    }

    return $new;
}

#-----------------------------------------------------------------------------#
# METHODS                                                                     #
#           functions operating on List and returning another List            #
#-----------------------------------------------------------------------------#

sub fold($list, $state, $folder) {
    my $xs = $list;
    my $s  = $state;
    while ( not is_empty($xs) ) {
        $s  = $folder->($s, head($xs));
        $xs = tail($xs);
    }
    return $s;
}

sub fold_mut($list, $state, $folder) {
    my $xs = $list;
    my $s  = $state;
    while ( not is_empty($xs) ) {
        $folder->($s, head($xs));
        $xs = tail($xs);
    }
    return $s;
}

sub fold_back($list, $state, $folder) {
    my $l = $list;

    # First build a stack from list
    my @stack;
    while ( not is_empty($l) ) {
        push @stack, $l->[0];
        $l = $l->[1];
    }

    # build new state by pop every element from stack
    my $s = $state;
    while ( my $x = pop @stack ) {
        $s = $folder->($s, $x);
    }

    return $s;
}

sub append($listA, $listB) {
    state $folder = sub($list, $x) { cons('List', $x, $list) };
    return fold_back($listA, $listB, $folder);
}

sub rev($list) {
    state $folder = sub($state, $x) { cons(List => $x, $state) };
    return fold($list, empty('List'), $folder);
}

sub map($list, $f) {
    return unfold(List => $list, sub($list) {
        return undef if is_empty($list);
        return $f->(head($list)), tail($list);
    });
}

sub mapi($list, $f) {
    my $idx = 0;
    return unfold(List => $list, sub($list) {
        return undef if is_empty($list);
        return $f->(head($list), $idx++), tail($list);
    });
}

sub map2($listA, $listB, $f) {
    my ($la, $lb) = ($listA, $listB);
    my $new       = empty('List');
    my $tail      = $new;

    while (1) {
        return $new if is_empty($la) || is_empty($lb);
        $tail = $mut_append->($tail, $f->(head($la), head($lb)));
        ($la, $lb) = (tail($la), tail($lb));
    }
}

sub choose($list, $chooser) {
    my $new  = empty('List');
    my $tail = $new;

    iter($list, sub($x) {
        my $y = $chooser->($x);
        if ( defined $y ) {
            $tail = $mut_append->($tail, $y);
        }
    });

    return $new;
}

# bind : list<'a> -> ('a -> list<'b>) -> list<'b>
sub bind($list, $f) {
    my $new  = empty('List');
    my $tail = $new;

    while (1) {
        return $new if is_empty($list);

        my $xs = $f->(head($list));
        while ( not is_empty($xs) ) {
            $tail = $mut_append->($tail, head($xs));
            $xs   = tail($xs);
        }
        $list = tail($list);
    }
}

sub flatten($list) {
    my $new  = empty('List');
    my $tail = $new;

    iter($list, sub($l) {
        iter($l, sub($x) {
            $tail = $mut_append->($tail, $x);
        });
    });

    return $new;
}

sub filter($list, $predicate) {
    my $new  = empty('List');
    my $tail = $new;

    iter($list, sub($x) {
        if ( $predicate->($x) ) {
            $tail = $mut_append->($tail, $x);
        }
    });

    return $new;
}

sub take($list, $amount) {
    my $l = $list;
    return unfold(List => $amount, sub($amount) {
        return undef if ($amount <= 0) || is_empty($l);

        my $head = head($l);
        $l = tail($l);
        return $head, ($amount-1);
    });
}

sub skip($list, $amount) {
    my $l = $list;
    while ( $amount-- > 0 ) {
        return $l if is_empty($l);
        $l = tail($l);
    }
    return $l;
}

sub zip($listA, $listB) {
    return map2($listA, $listB, sub($x,$y) { [$x,$y] });
}

sub indexed($list) {
    my $idx = 0;
    return List::map($list, sub($x) { [$idx++, $x] });
}

sub distinct_by($list, $mapper) {
    my $new  = empty('List');
    my $tail = $new;
    my %seen;
    iter($list, sub($x) {
        my $key = $mapper->($x);
        if ( not exists $seen{$key} ) {
            $seen{$key} = 1;
            $tail = $mut_append->($tail, $x);
        }
    });
    return $new;
}

sub distinct($list) {
    return distinct_by($list, sub($x) { $x });
}

sub sort($list, $comparer) {
    return from_array('List', Array::sort(to_array($list), $comparer));
}

sub sort_by($list, $comparer, $get_key) {
    return from_array('List', Array::sort_by(to_array($list), $comparer, $get_key));
}

sub fsts($list) {
    return List::map($list, sub($tuple) { $tuple->[0] });
}

sub snds($list) {
    return List::map($list, sub($tuple) { $tuple->[1] });
}

sub flatten_array($list) {
    my $new  = empty('List');
    my $tail = $new;

    iter($list, sub($array) {
        for my $x ( @$array ) {
            $tail = $mut_append->($tail, $x);
        }
    });

    return $new;
}

sub windowed($list, $window_size) {
    my $new  = empty('List');
    my $tail = $new;
    return $new if is_empty($list) || $window_size <= 0;

    my $array = to_array($list);
    my $length     = $window_size - 1;
    my $last_index = @$array - $length;
    for (my $index=0; $index < $last_index; $index++) {
        my $window = [$array->@[$index .. ($index + $length)]];
        $tail = $mut_append->($tail, $window);
    }
    return $new;
}

sub intersperse($list, $value) {
    return empty('List')             if is_empty($list);
    return wrap('List', head($list)) if is_empty(tail($list));

    my $new   = wrap('List', head($list));
    my $tail  = $new->[1];

    my $l     = tail($list);
    my $emit  = 1;
    while ( not is_empty($l) ) {
        if ( $emit ) {
            $tail = $mut_append->($tail, $value);
            $emit = 0;
        }
        else {
            $tail = $mut_append->($tail, head($l));
            $emit = 1;
            $l = tail($l);
        }
    }

    return $new;
}

sub repeat($list, $amount) {
    my $new  = empty('List');
    my $tail = $new;

    for ( 1 .. $amount ) {
        iter($list, sub($x) {
            $tail = $mut_append->($tail, $x);
        });
    }

    return $new;
}

#-----------------------------------------------------------------------------#
# SIDE-EFFECTS                                                                #
#    functions that have side-effects or produce side-effects. Those are      #
#    immediately executed                                                     #
#-----------------------------------------------------------------------------#

sub iter($list, $f) {
    my $l = $list;
    while ( not is_empty($l) ) {
        $f->(head($l));
        $l = tail($l);
    }
    return;
}

#-----------------------------------------------------------------------------#
# CONVERTER                                                                   #
#         Those are functions converting List to none List types              #
#-----------------------------------------------------------------------------#

sub reduce($list, $default, $reducer) {
    # return $default if $list is empty
    return $default if is_empty($list);
    my $state = head($list);
    my $l     = tail($list);
    # return first element if $list only contains one element
    return $state if is_empty($l);
    # otherwise reduce
    iter($l, sub($x) {
        $state = $reducer->($state, $x);
    });
    return $state;
}

sub to_array($list) {
    state $folder = sub($state, $x) { push @$state, $x };
    return fold_mut($list, [], $folder);
}

sub expand($list) {
    return @{ to_array($list) };
}

sub count($list) {
    state $folder = sub($state, $x) { $state + 1 };
    return fold($list, 0, $folder);
}

sub sum($list) {
    state $folder = sub($state, $x) { $state + $x };
    return fold($list, 0, $folder);
}

sub sum_by($list, $f) {
    return fold($list, 0, sub($state, $x) { $state + $f->($x) });
}

sub str_join($list, $sep) {
    return CORE::join($sep, expand($list));
}

sub to_hash($list, $mapper) {
    return fold_mut($list, {}, sub($hash, $x) {
        my ($key, $value) = $mapper->($x);
        $hash->{$key} = $value;
    });
}

sub to_hash_of_array($list, $mapper) {
    return fold_mut($list, {}, sub($hash, $x) {
        my ($key, $value) = $mapper->($x);
        push $hash->{$key}->@*, $value;
    });
}

sub find($list, $default, $predicate) {
    my $l = $list;
    while ( not is_empty($l) ) {
        my $x = head($l);
        if ( $predicate->($x) ) {
            return $x;
        }
        $l = tail($l);
    }
    return $default;
}

sub first($list, $default) {
    return $default if is_empty($list);
    return head($list);
}

sub last($list, $default) {
    return $default if is_empty($list);
    my $last;
    iter($list, sub($x) {
        $last = $x;
    });
    return $last;
}

sub to_array_of_array($lol) {
    my @array;
    iter($lol, sub($list) {
        push @array, to_array($list);
    });
    return \@array;
}

sub any($list, $predicate) {
    my $l = $list;
    while ( not is_empty($l) ) {
        if ( $predicate->(head($l)) ) {
            return 1;
        }
        $l = tail($l);
    }
    return 0;
}

sub all($list, $predicate) {
    my $l = $list;
    while ( not is_empty($l) ) {
        if ( not $predicate->(head($l)) ) {
            return 0;
        }
        $l = tail($l);
    }
    return 1;
}

sub none($list, $predicate) {
    my $l = $list;
    while ( not is_empty($l) ) {
        if ( $predicate->(head($l)) ) {
            return 0;
        }
        $l = tail($l);
    }
    return 1;
}

sub pick($list, $default, $picker) {
    my $l = $list;
    while ( not is_empty($l) ) {
        my $x = $picker->(head($l));
        return $x if defined $x;
        $l = tail($l);
    }
    return $default;
}

sub regex_match($list, $regex, $picks) {
    my $new  = empty('List');
    my $tail = $new;

    my $l = $list;
    while ( not is_empty($l) ) {
        my $str = head($l);
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
            $tail = $mut_append->($tail, \@matches);
        }
        $l = tail($l);
    }
    return $new;
}

1;