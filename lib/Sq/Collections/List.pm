package List;
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort', 'map';
use Scalar::Util ();
use List::Util ();
use Carp ();

#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create sequences                          #
#-----------------------------------------------------------------------------#

sub empty($class)              { return bless([],             'List') }
sub cons($class, $head, $tail) { return bless([$head, $tail], 'List') }

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

sub head($list) { return $list->[0] }
sub tail($list) { return $list->[1] }

sub is_empty($list) {
    return 1 if Scalar::Util::reftype $list eq 'ARRAY' && @$list == 0;
    return 0;
}

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

1;