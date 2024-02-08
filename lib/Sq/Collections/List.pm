package List;
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort', 'map';
use Scalar::Util ();
use List::Util ();
use Carp ();

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

#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create sequences                          #
#-----------------------------------------------------------------------------#

# List->unfold : 'State -> ('State -> Option<ListContext<'a, 'State>>) -> List<'a>
sub unfold($class, $state, $f) {
    my $s    = $state;
    my $list = empty('List');
    my $tail = $list;

    my $x;
    while (1) {
        ($x, $s) = $f->($s);
        goto RETURN if not defined($x);
        $tail->[0] = $x;
        $tail->[1] = empty('List');
        $tail      = $tail->[1];
    }

    RETURN:
    return $list;
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

#-----------------------------------------------------------------------------#
# METHODS                                                                     #
#           functions operating on Seq and returning another Seq              #
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

sub rev($list) {
    state $folder = sub($state, $x) {
        return cons(List => $x, $state);
    };
    return fold($list, empty('List'), $folder);
}

sub map($list, $f) {
    return unfold(List => $list, sub($list) {
        return undef if is_empty($list);
        return $f->(head($list)), tail($list);
    });
}

# bind : list<'a> -> ('a -> list<'b>) -> list<'b>
sub bind($list, $f) {
    my $new  = empty('List');
    my $tail = $new;

    NEXT:
    return $new if is_empty($list);

    my $head = head($list);
    my $xs   = $f->($head);

    while ( not is_empty($xs) ) {
        my $x = head($xs);
        $tail->[0] = $x;
        $tail->[1] = empty('List');
        $tail      = $tail->[1];
        $xs        = tail($xs);
    }

    $list = tail($list);
    goto NEXT;
}

sub filter($list, $predicate) {
    return unfold(List => $list, sub($list) {
        NEXT:
        return undef if is_empty($list);
        my $head = head($list);
        if ( $predicate->($head) ) {
            return $head, tail($list);
        }
        else {
            $list = tail($list);
            goto NEXT;
        }
    });
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

#-----------------------------------------------------------------------------#
# SIDE-EFFECTS                                                                #
#    functions that have side-effects or produce side-effects. Those are      #
#    immediately executed, usually consuming all elements of Seq at once.     #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
# CONVERTER                                                                   #
#         Those are functions converting Array to none Array types            #
#-----------------------------------------------------------------------------#

sub to_array($list) {
    state $folder = sub($state, $x) {
        push @$state, $x;
    };
    return fold_mut($list, [], $folder);
}

sub expand($list) {
    return @{ to_array($list) };
}

sub count($list) {
    return fold($list, 0, sub($state, $x) { $state+1 });
}

sub sum($list) {
    return fold($list, 0, sub($state, $x) { $state+$x });
}

1;