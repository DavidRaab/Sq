package Seq;
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort', 'map', 'foreach', 'length';
use Scalar::Util ();
use List::Util ();
use Carp ();

# TODO:
#       Find another name for 'from_list'
#       chain
#       regex_replace
#       extract(predicate, predicate)
#       foldBack, average, average_by,
#       pairwise, transpose, chunk_by_size, unzip
#       transpose, slice
#       minmax, minmax_by,
#       scan, mapFold, except/exclude
#       splitInto
#     ? contains, firstIndex, mapX, on
#
# + ways to do regexes on strings
# + using this module to scan file-system
# ? how about a data checker tool
# + more ways to transform data, especially complex structures
# ? A data transformation/selection language
# o Error checking through another module that adds signature type check through AOP
# o Maybe DU, Record fist-class support when i implement them.
# o good way to also implement async with it?

#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create sequences                          #
#-----------------------------------------------------------------------------#

# creates a sequence from a subroutine
sub from_sub($, $f) {
    return bless(sub {
        my $abort = 0;
        my $it    = $f->();
        my $x;
        return sub {
            return undef if $abort;
            if ( defined($x = $it->()) ) {
                return $x;
            }
            $abort = 1;
            undef $it;
        }
    }, 'Seq');
}

# always return $x
sub always($, $x) {
    bless(sub { sub { $x } }, 'Seq');
}

# empty sequence
sub empty($) {
    state $empty = bless(sub { sub { undef } }, 'Seq');
    return $empty;
}

# replicates an $initial value $count times
sub replicate($, $count, $initial) {
    from_sub(Seq => sub {
        my $amount = 0;
        return sub {
            return undef if $amount++ >= $count;
            return $initial;
        }
    });
}

# TODO: When $state is a reference. Same handling as in fold?
#
# Seq->unfold : 'State -> ('State -> Option<'a,'State>) -> Seq<'a>
sub unfold($, $state, $f_opt) {
    bless(sub {
        my $abort = 0;
        # IMPORTANT: Perl signatures are aliases. As we assign
        # to $state later, we need to make a copy here.
        # Removing this lines causes bugs.
        my $state = $state;
        my ($is_some, $x);
        return sub {
            return undef if $abort;
            ($is_some, $x, $state) = Option->extract($f_opt->($state));
            return $x if $is_some;
            $abort = 1;
            undef $state;
            undef $x;
        }
    }, 'Seq');
}

# Seq->init: int -> (int -> 'a) -> Seq<'a>
sub init($, $count, $f) {
    bless(sub {
        my $abort   = 0;
        my $current = 0;
        return sub {
            return undef if $abort;
            return $f->($current++) if $current < $count;
            $abort = 1;
            return undef;
        }
    }, 'Seq');
}

# Seq->range_step: float -> float -> float -> Seq<float>
sub range_step($, $start, $step, $stop) {
    Carp::croak '$step is 0. Will run forever.' if $step == 0;

    # Ascending order
    if ( $start <= $stop ) {
        return bless(sub {
            my $abort   = 0;
            my $current = $start;
            my $next    = $current;

            return sub {
                return undef if $abort;
                $current = $next;
                $next   += $step;
                return $current if $current <= $stop;
                $abort = 1;
                return undef;
            }
        }, 'Seq');
    }
    # Descending
    else {
        return bless(sub {
            my $abort   = 0;
            my $current = $start;
            my $next    = $current;

            return sub {
                return undef if $abort;
                $current = $next;
                $next   -= $step;
                return $current if $current >= $stop;
                $abort = 1;
                return undef;
            }
        }, 'Seq');
    }
}

# Seq->new : List<'a> -> Seq<'a>
sub new($, @xs) {
    return bless(sub {
        my $abort = 0;
        my $idx   = 0;
        my $x;
        return sub {
            return undef if $abort;
            return $x if defined($x = $xs[$idx++]);
            $abort = 1;
            return undef;
        }
    }, 'Seq');
}

sub wrap($, @xs) {
    return new('Seq', @xs);
}

# Seq->range : int -> int -> Seq<int>
sub range($, $start, $stop) {
    $start = int $start;
    $stop  = int $stop;

    # when same return seq with one item
    return new('Seq', $start) if $start == $stop;

    # ascending order
    if ( $start < $stop ) {
        return bless(sub {
            my $abort   = 0;
            my $current = $start;
            return sub {
                return undef if $abort;
                if ( $current > $stop ) {
                    $abort = 1;
                    return undef;
                }
                return $current++;
            }
        }, 'Seq');
    }
    # descending order
    else {
        return bless(sub {
            my $abort   = 0;
            my $current = $start;
            return sub {
                return undef if $abort;
                if ( $current < $stop ) {
                    $abort = 1;
                    return undef;
                }
                return $current--;
            }
        }, 'Seq');
    }
}

# Seq->from_array : Array<'a> -> Seq<'a>
sub from_array($, $xs) {
    return bless(sub {
        my $abort = 0;
        my $idx   = 0;
        my $x;
        return sub {
            return undef if $abort;
            return $x if defined($x = $xs->[$idx++]);
            $abort = 1;
            return undef;
        }
    }, 'Seq');
}

# Seq->from_hash : Hash<'Key, 'Value> -> ('Key -> 'Value -> 'a) -> Seq<'a>
sub from_hash($, $hashref, $f) {
    from_sub('Seq', sub {
        my $idx  = 0;
        my @keys = keys %$hashref;
        my $last = $#keys;
        my $key;
        return sub {
            return undef if $idx > $last;
            $key = $keys[$idx++];
            return $f->($key, $hashref->{$key});
        }
    });
}

# Seq->concat : List<Seq<'a>> -> Seq<'a>
sub concat($, @seqs) {
    my $count = @seqs;

    # with no values to concat, return an empty iterator
    return empty('Seq') if $count == 0;
    # one element can be returned as-is
    return $seqs[0]     if $count == 1;
    # at least two items
    return List::Util::reduce { append($a, $b) } @seqs;
}

#----------------------------------------------------------------------------#
# METHODS                                                                    #
#          functions operating on Seq and returning another Seq              #
#----------------------------------------------------------------------------#

# noop, only there for API compatibility
sub copy($seq) {
    return $seq;
}

# append : Seq<'a> -> Seq<'a> -> Seq<'a>
sub append($seqA, $seqB) {
    from_sub('Seq', sub {
        my $exhaustedA = 0;
        my $itA = $seqA->();
        my $itB;
        my $x;

        return sub {
            REDO:
            if ( $exhaustedA ) {
                return $itB->();
            }
            else {
                if ( defined($x = $itA->()) ) {
                    return $x;
                }

                undef $itA;
                $exhaustedA = 1;
                $itB = $seqB->();
                goto REDO;
            }
        };
    });
}

# map : Seq<'a> -> ('a -> 'b) -> Seq<'b'>
sub map($seq, $f) {
    return bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my $x;
        return sub {
            return undef if $abort;
            if ( defined($x = $it->()) ) {
                return $f->($x);
            }
            $abort = 1;
            undef $it;
        }
    }, 'Seq');
}

# map2 : Seq<'a> -> Seq<'b> -> ('a -> 'b -> 'c) -> Seq<'c>
sub map2($seqA, $seqB, $f) {
    return bless(sub {
        my $abort = 0;
        my $itA   = $seqA->();
        my $itB   = $seqB->();
        my ($a,$b);
        return sub {
            return undef if $abort;
            if ( defined($a = $itA->()) ) {
            if ( defined($b = $itB->()) ) {
                return $f->($a,$b);
            }}
            $abort = 1;
            undef $itA;
            undef $itB;
        }
    }, 'Seq');
}

# bind : Seq<'a> -> ('a -> Seq<'b>) -> Seq<'b>
sub bind($seq, $f) {
    return bless(sub {
        # 0 = read from $itA
        # 1 = read from $itB
        # 2 = undef
        my $state = 0;

        my $itA  = $seq->();
        my $itB  = undef;
        my ($a, $b);
        return sub {
            REDO:
            # read from $itA
            if ( $state == 0 ) {
                $a = $itA->();
                if ( defined $a ) {
                    $itB   = $f->($a)->();
                    $state = 1;
                }
                else {
                    $state = 2;
                    undef $itA;
                    undef $itB;
                    undef $a;
                }
            }

            # read from $itB
            if ( $state == 1 ) {
                $b = $itB->();
                if ( defined $b ) {
                    return $b;
                }
                else {
                    $state = 0;
                    goto REDO;
                }
            }

            return undef;
        }
    }, 'Seq');
}

# flatten : Seq<Seq<'a>> -> Seq<'a>
sub flatten($seq) {
    return bind($seq, \&Sq::id);
}

# flatten_array : Seq<Array<'a>> -> Seq<'a>
sub flatten_array($seq) {
    return bind($seq, sub($array) {
        return from_array('Seq', $array);
    });
}

# cartesian : Seq<'a> -> Seq<'b> -> Seq<'a * 'b>
sub cartesian($seqA, $seqB) {
    bind($seqA, sub($a) {
    bind($seqB, sub($b) {
        new('Seq', CORE::bless([$a, $b], 'Array'));
    })});
}

# join creates the cartesian product, but only for those elements
# $predicate returns true.
# join : Seq<'a> -> Seq<'b> -> ('a -> 'b -> bool) -> Seq<'a * 'b>
sub left_join($seqA, $seqB, $predicate) {
    bind($seqA, sub($a) {
    bind($seqB, sub($b) {
        return new(Seq => [$a, $b]) if $predicate->($a, $b);
        return empty('Seq');
    })});
}

# Expects a sequence of tuples. For example what join returns.
# Provides a merging function to combine 'a and 'b into something new 'c
# merge : Seq<'a * 'b> -> ('a -> 'b -> 'c) -> Seq<'c>
sub merge($seq, $merge) {
    bind($seq, sub($tuple) {
        return new(Seq => $merge->($tuple->[0], $tuple->[1]));
    });
}

# Merges a sequence that contains tuples with hashes. Like: [{...}, {...}]
# $mapA contains the selection from the first element of the tuple
# $mapB contains the selection from the second element of the tuple
#
# Selection can either be a hashref mapping a hashnames to a
# new hashname { id => 'some_id' }
#
# or an array of names that should be picked: [qw/id name/]
sub select($seq, $mapA, $mapB) {
    # Transforms the different inputs a user can give into a
    # hash and an array containing the keys
    state $gen_input = sub($mapping) {
        my $hash;
        my $keys;
        if ( not defined Scalar::Util::reftype $mapping) {
            if ( $mapping =~ m/\Aall\z/i ) {
                return ['ALL'];
            }
            elsif ( $mapping =~ m/\Anone\z/i ) {
                return ['NONE'];
            }
            else {
                Carp::croak "When not arrayref or hashref must be either 'ALL' or 'NONE'";
            }
        }
        elsif ( Scalar::Util::reftype $mapping eq 'HASH' ) {
            $hash = $mapping;
            $keys = [ keys $mapping->%* ];
        }
        elsif ( Scalar::Util::reftype $mapping eq 'ARRAY' ) {
            $hash = { map { $_ => $_ } @$mapping };
            $keys = $mapping;
        }
        else {
            Carp::croak '$mappings must be tuple and either contain hashref or arrayref';
        }

        # Returns a discriminated union with three cases
        # ['ALL']
        # ['NONE']
        # ['SELECTION', $mapping, $keys]
        return [SELECTION => $hash, $keys];
    };

    my $caseA = $gen_input->($mapA);
    my $caseB = $gen_input->($mapB);

    merge($seq, sub($a, $b) {
        my %new_hash;

        # Merge keys from $seqA
        if ( $caseA->[0] eq 'ALL' ) {
            # Copies hash
            %new_hash = %$a;
        }
        elsif ( $caseA->[0] eq 'NONE' ) {
            # do nothing here ...
        }
        else {
            my ($mapping, $keys) = $caseA->@[1,2];
            for my $key ( @$keys ) {
                $new_hash{$mapping->{$key}} = $a->{$key};
            }
        }

        # Merge keys from $seqB
        if ( $caseB->[0] eq 'ALL' ) {
            # add keys from $b to new hash
            for my $key ( keys %$b ) {
                $new_hash{$key} = $b->{$key};
            }
        }
        elsif ( $caseB->[0] eq 'NONE' ) {
            # do nothing here ...
        }
        else {
            my ($mapping, $keys) = $caseB->@[1,2];
            for my $key ( @$keys ) {
                $new_hash{$mapping->{$key}} = $b->{$key};
            }
        }

        return \%new_hash;
    });
}

# choose : Seq<'a> -> ('a -> option<'b>) -> Seq<'b>
sub choose($seq, $f_opt) {
    from_sub('Seq', sub {
        my $it = $seq->();
        my ($x, $is_some, $v);
        return sub {
            while ( defined($x = $it->()) ) {
                ($is_some, $v) = Option->extract($f_opt->($x));
                return $v if $is_some;
            }
            return undef;
        }
    });
}

# mapi : Seq<'a> -> ('a -> int -> 'b) -> Seq<'b>
sub mapi($seq, $f) {
    from_sub(Seq => sub {
        my $it  = $seq->();
        my $idx = 0;
        return sub {
            my $x = $it->();
            return undef if not defined $x;
            return $f->($x, $idx++);
        }
    });
}

# filter : Seq<'a> -> ('a -> bool) -> Seq<'a>
sub filter($seq, $predicate) {
    return bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my $x;
        return sub {
            return undef if $abort;
            while ( defined($x = $it->()) ) {
                return $x if $predicate->($x);
            }
            $abort = 1;
            undef $it;
        }
    }, 'Seq');
}

# take : Seq<'a> -> int -> Seq<'a>
sub take($seq, $amount) {
    return bless(sub {
        my $abort         = 0;
        my $it            = $seq->();
        my $returnedSoFar = 0;
        my $x;
        return sub {
            return undef if $abort;
            if ( $returnedSoFar++ < $amount ) {
                if ( defined($x = $it->()) ) {
                    return $x;
                }
                $abort = 1;
                undef $it;
            }

            return undef;
        }
    }, 'Seq');
}

# take_while : Seq<'a> -> ('a -> bool) -> Seq<'a>
sub take_while($seq, $predicate) {
    from_sub('Seq', sub {
        my $it = $seq->();
        my $value;
        return sub {
            $value = $it->();
            return $value if $predicate->($value);
            return undef;
        };
    });
}

# skip : Seq<'a> -> int -> Seq<'a>
sub skip($seq, $amount) {
    from_sub('Seq', sub {
        my $it = $seq->();
        my $count = 0;
        return sub {
            while ( $count++ < $amount ) {
                $it->();
            }
            return $it->();
        }
    });
}

# skip_while : Seq<'a> -> ('a -> bool) -> Seq<'a>
sub skip_while($seq, $predicate) {
    from_sub('Seq', sub {
        my $it = $seq->();
        my $first;
        while (1) {
            $first = $it->();
            last if not ($predicate->($first))
        }
        return sub {
            if ( defined $first ) {
                my $x = $first;
                undef $first;
                return $x;
            }
            else {
                return $it->();
            }
        }
    });
}

# indexed : Seq<'a> -> Seq<'a * int>
sub indexed($seq) {
    my $index = 0;
    return Seq::map($seq, sub($x) {
        return Array->new($x, $index++);
    });
}

# distinct_by : Seq<'a> -> ('a -> 'Key) -> Seq<'a>
sub distinct_by($seq, $f) {
    from_sub(Seq => sub {
        my $it = $seq->();
        my %seen;
        my $x;
        return sub {
            SKIP:
            if ( defined($x = $it->()) ) {
                my $key = $f->($x);
                goto SKIP if exists $seen{$key};
                $seen{$key} = 1;
                return $x;
            }
            return undef;
        }
    });
}

# distinct : Seq<'a> -> Seq<'a>
sub distinct($seq) {
    return distinct_by($seq, \&Sq::id);
}

# TODO: Instead of fsts and snds provide a function to pick the index of an array.
#       Maybe even a function to pick and re-order multiple elements
#         Like: ->pick([3,1,5])

# fsts : Seq<'a * 'b> -> Seq<'a>
sub fsts($seq) {
    return Seq::map($seq, sub ($x) { $x->[0] });
}

# snds : Seq<'a * 'b> -> Seq<'b>
sub snds($seq) {
    return Seq::map($seq, sub ($x) { $x->[1] });
}

# TODO: zip can handle a list of sequences
#
# zip : Seq<'a> -> Seq<'b> -> Seq<'a * 'b>
sub zip($seqA, $seqB) {
    from_sub('Seq', sub {
        my $itA = $seqA->();
        my $itB = $seqB->();
        my ($a, $b);

        return sub {
            if (defined ($a = $itA->())) {
            if (defined ($b = $itB->())) {
                return Array->new($a,$b);
            }}
            return undef;
        }
    });
}

# rev : Seq<'a> -> Seq<'a>
sub rev($seq) {
    from_sub('Seq', sub {
        my $list = to_array($seq);
        return sub {
            pop @$list;
        };
    });
}

# sort : Seq<'a> -> ('a -> 'a -> int) -> Seq<'a>
sub sort($seq, $comparer) {
    from_sub('Seq', sub {
        local ($a, $b);
        my $array  = to_array($seq);
        my @sorted = CORE::sort { $comparer->($a, $b) } @$array;
        my $idx    = 0;

        return sub {
            return $sorted[$idx++];
        };
    });
}

# sort_by : Seq<'a> -> ('Key -> 'Key -> int) -> ('a -> 'Key) -> Seq<'a>
sub sort_by($seq, $comparer, $get_key) {
    from_sub('Seq', sub {
        local ($a, $b, $_);
        my $idx    = 0;
        my $array  = to_array($seq);
        my @sorted =
            CORE::map  { $_->[1] }
            CORE::sort { $comparer->($a->[0], $b->[0]) }
            CORE::map  { [$get_key->($_), $_] }
                @$array;

        return sub {
            return $sorted[$idx++];
        }
    });
}

# cache : Seq<'a> -> Seq<'a>
sub cache($seq) {
    return from_array('Seq', to_array($seq));
}

# regex_match : Seq<string> -> Regex -> Seq<Array<string>>
sub regex_match($seq, $regex) {
    from_sub(Seq => sub {
        my $it = $seq->();
        return sub {
            NEXT_LINE:
            my $str = $it->();
            return undef if not defined $str;
            if ( $str =~ $regex ) {
                return CORE::bless([@{^CAPTURE}], 'Array');
            }
            goto NEXT_LINE;
        }
    });
}

sub regex_sub($seq, $regex, $fn) {
    from_sub(Seq => sub {
        my $it = $seq->();
        return sub {
            NEXT_LINE:
            my $str = $it->();
            return undef if not defined $str;
            $str =~ s/$regex/$fn->()/oe;
            return $str;
        };
    });
}

# TODO: Really Seq<Array<'a>> as return value? Seq<Seq<'a>> instead?
# TODO: Not completely lazy
# windowed : Seq<'a> -> int -> Seq<Array<'a>>
sub windowed($seq, $window_size) {
    return empty('Seq') if $window_size <= 0;
    from_sub(Seq => sub {
        my $array      = Array::windowed(to_array($seq), $window_size);
        my $last_index = scalar @$array;
        my $index      = 0;

        return sub {
            return undef if $index >= $last_index;
            return $array->[$index++];
        }
    });
}

# intersperse : Seq<'a> -> 'a -> Seq<'a>
sub intersperse($seq, $sep) {
    from_sub(Seq => sub() {
        my $it = $seq->();
        my $x  = $it->();
        my $y  = $it->();

        # 0 = return $x, and advance $it forward
        # 1 = return $sep
        # 2 = return $x, and finish
        # 3 = finish
        my $state; {
            if ( defined $x ) {
                $state = defined $y ? 0 : 2;
            }
            else {
                $state = 3;
            }
        }
        return sub {
            if ( $state == 0 ) {
                my $ret = $x;
                $x      = $y;
                $y      = $it->();
                $state  = 1;
                return $ret;
            }
            elsif ( $state == 1 ) {
                $state = defined $y ? 0 : 2;
                return $sep;
            }
            elsif ( $state == 2 ) {
                $state = 3;
                return $x;
            }
            else {
                return undef;
            }
        }
    });
}

# infinity : Seq<'a> -> Seq<'a>
sub infinity($seq) {
    from_sub(Seq => sub {
        my $it = $seq->();
        my $x  = $it->();
        return sub {
            if ( defined $x ) {
                my $tmp = $x;
                $x = $it->();
                if ( not defined $x ) {
                    $it = $seq->();
                    $x  = $it->();
                }
                return $tmp;
            }
            else {
                return undef;
            }
        }
    });
}

# repeat : Seq<'a> -> int -> Seq<'a>
sub repeat($seq, $count) {
    from_sub(Seq => sub {
        my $count = $count;
        my $it    = $seq->();
        my $x     = $it->();
        return sub {
            return undef if $count <= 0;
            if ( defined $x ) {
                my $tmp = $x;
                $x = $it->();
                if ( not defined $x ) {
                    $count--;
                    $it = $seq->();
                    $x  = $it->();
                }
                return $tmp;
            }
            else {
                return undef;
            }
        }
    });
}


#-----------------------------------------------------------------------------#
# SIDE-EFFECTS                                                                #
#    functions that have side-effects or produce side-effects. Those are      #
#    immediately executed, usually consuming all elements of Seq at once.     #
#-----------------------------------------------------------------------------#

# iter : Seq<'a> -> ('a -> unit) -> unit
sub iter($seq, $f) {
    my $it = $seq->();
    my $x;
    $f->($x) while defined($x = $it->());
    return;
}

# same as iter
sub foreach($seq, $f) {
    my $it = $seq->();
    my $x;
    $f->($x) while defined($x = $it->());
    return;
}

sub iteri($seq, $f) {
    my $it        = $seq->();
    my ($idx, $x) = (0, undef);
    while ( defined($x = $it->()) ) {
        $f->($x, $idx++);
    }
    return;
}

# same as iteri
sub foreachi($seq, $f) {
    my $it        = $seq->();
    my ($idx, $x) = (0, undef);
    while ( defined($x = $it->()) ) {
        $f->($x, $idx++);
    }
    return;
}

# Similar to iter(). But returns the $seq as-is.
# Useful for doing something between a chain. For example printing
# all elements of a sequence.
#
# $seq->do(sub($x) { print Dumper($x) })->...
#
# do : Seq<'a> -> ('a -> unit) -> Seq<'a>
sub do($seq, $f) {
    return from_sub(Seq => sub {
        my $it = $seq->();
        my $x;

        return sub {
            if ( defined($x = $it->()) ) {
                $f->($x);
                return $x;
            }
            return undef;
        }
    });
}

# Same as do() but also provides an index
sub doi($seq, $f) {
    return from_sub(Seq => sub {
        my $it        = $seq->();
        my ($idx, $x) = (0, undef);

        return sub {
            if ( defined($x = $it->()) ) {
                $f->($x, $idx++);
                return $x;
            }
            return undef;
        }
    });
}


#----------------------------------------------------------------------#
# CONVERTER                                                            #
#         Those are functions converting Seq to none Seq types         #
#----------------------------------------------------------------------#

# group_fold :
#   Seq<'a>
#   -> (unit -> 'State)
#   -> ('a -> 'Key)
#   -> ('State -> 'a -> 'State)
#   -> Hash<'Key,'State>
sub group_fold($seq, $get_state, $get_key, $folder) {
    my $new = Hash->new;
    iter($seq, sub($a) {
        my $key = $get_key->($a);
        if ( exists $new->{$key} ) {
            $new->{$key} = $folder->($new->{$key}, $a);
        }
        else {
            $new->{$key} = $folder->($get_state->(), $a);
        }
    });
    return $new;
}

# group_by : Seq<'a> -> ('a -> 'Key) -> Hash<'Key,Array<'a>>
sub group_by($seq, $get_key) {
    state $new_array = sub()      { Array->new        };
    state $folder    = sub($s,$x) { push(@$s, $x); $s };
    return group_fold($seq, $new_array, $get_key, $folder);
}

# fold : Seq<'a> -> 'State -> ('a -> 'State -> 'State) -> 'State
sub fold($seq, $state, $f_state) {
    my $it     = $seq->();
    my $result = $state;
    my $x;
    while ( defined($x = $it->()) ) {
        $result = $f_state->($x,$result);
    }
    return $result;
}

# fold_mut : Seq<'a> -> 'State -> ('a -> 'State -> unit) -> 'State
sub fold_mut($seq, $state, $f_state) {
    my $it = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        $f_state->($x,$state);
    }
    return $state;
}

# reduce: Seq<'a> -> ('a -> 'a -> 'a) -> 'a
sub reduce($seq, $reducer) {
    return first($seq)->map(sub($first) {
        return fold(skip($seq, 1), $first, $reducer);
    });
}

# first : Seq<'a> -> Option<'a>
sub first($seq) {
    return Option::Some($seq->()());
}

# last : Seq<'a> -> Option<'a>
sub last($seq) {
    my $it = $seq->();
    my ($last, $x);
    while ( defined($x = $it->()) ) {
        $last = $x;
    }
    return Option::Some($last);
}

# TODO: first_match / last_match

# to_array : Seq<'a> -> Array<'a>
sub to_array($seq, $count=undef) {
    my $new = Array->new;
    my $it  = $seq->();
    my $x;
    if ( defined $count ) {
        my $current = 0;
        while ( $current++ < $count ) {
            if ( defined($x = $it->()) ) {
                push @$new, $x;
            }
        }
    }
    else {
        while ( defined($x = $it->()) ) {
            push @$new, $x;
        }
    }
    return $new;
}

# to_seq: Seq<'a> -> Seq<'a>
sub to_seq($seq) {
    return $seq;
}

# expand : Seq<'a> -> ListContext<'a>
sub expand($seq) {
    return @{ to_array($seq) };
}

# length : Seq<'a> -> int
sub length($seq) {
    state $folder = sub($x,$count) { $count+1 };
    return fold($seq, 0, $folder);
}

# sum : Seq<'a> -> float
sub sum($seq) {
    state $folder = sub($x,$sum) { $sum + $x };
    return fold($seq, 0, $folder);
}

# sum_by : Seq<'a> -> (float -> 'a -> float) -> float
sub sum_by($seq, $f) {
    return fold($seq, 0, sub($x,$sum) {
        return $sum + $f->($x);
    });
}

# min : Seq<float> -> float -> Option<float>
sub min($seq) {
    my $it  = $seq->();
    my $min = $it->();
    return Option::None() if !defined $min;
    my $x;
    while ( defined($x = $it->()) ) {
        $min = $x if $x < $min;
    }
    return Option::Some($min);
}

# min_by : Seq<'a> -> ('a -> float) -> Option<'a>
sub min_by($seq, $f_num) {
    my $it  = $seq->();
    my $min = $it->();
    return Option::None() if !defined $min;
    my $min_num = $f_num->($min);
    my ($x, $num);
    while ( defined($x = $it->()) ) {
        $num = $f_num->($x);
        if ( $num < $min_num ) {
            $min     = $x;
            $min_num = $num;
        }
    }
    return Option::Some($min);
}

# min_str : Seq<string> -> string -> Option<string>
sub min_str($seq) {
    my $it  = $seq->();
    my $min = $it->();
    return Option::None() if !defined $min;
    my $x;
    while ( defined($x = $it->()) ) {
        $min = $x if $x lt $min;
    }
    return Option::Some($min);
}

# min_str_by : Seq<'a> -> ('a -> string) -> Option<'a>
sub min_str_by($seq, $f_str) {
    my $it  = $seq->();
    my $min = $it->();
    return Option::None() if !defined $min;
    my $min_str = $f_str->($min);
    my ($x, $str);
    while ( defined($x = $it->()) ) {
        $str = $f_str->($x);
        if ( $str lt $min_str ) {
            $min     = $x;
            $min_str = $str;
        }
    }
    return Option::Some($min);
}

# max : Seq<float> -> Option<float>
sub max($seq) {
    my $it  = $seq->();
    my $max = $it->();
    return Option::None() if !defined $max;
    my $x;
    while ( defined($x = $it->()) ) {
        $max = $x if $x > $max;
    }
    return Option::Some($max);
}

# max_by : Seq<'a> -> ('a -> float) -> Option<'a>
sub max_by($seq, $f_num) {
    my $it = $seq->();
    my $max = $it->();
    return Option::None() if !defined $max;
    my $max_num = $f_num->($max);
    my ($x, $num);
    while ( defined($x = $it->()) ) {
        $num = $f_num->($x);
        if ( $num > $max_num ) {
            $max     = $x;
            $max_num = $num;
        }
    }
    return Option::Some($max);
}

# max_str : Seq<string> -> Option<string>
sub max_str($seq) {
    my $it  = $seq->();
    my $max = $it->();
    return Option::None() if !defined $max;
    my $x;
    while ( defined($x = $it->()) ) {
        $max = $x if $x gt $max;
    }
    return Option::Some($max);
}

# max_str_by : Seq<'a> -> ('a -> string) -> Option<'a>
sub max_str_by($seq, $f_str) {
    my $it  = $seq->();
    my $max = $it->();
    return Option::None() if !defined $max;
    my $max_str = $f_str->($max);
    my ($x, $str);
    while ( defined($x = $it->()) ) {
        $str = $f_str->($x);
        if ( $str gt $max_str ) {
            $max     = $x;
            $max_str = $str;
        }
    }
    return Option::Some($max);
}

# str_join : Seq<string> -> string -> string
sub join($seq, $sep) {
    return CORE::join($sep, expand($seq));
}

sub split($seq, $regex) {
    return Seq::map($seq, sub($line) {
        bless([split $regex, $line], 'Array');
    });
}

sub as_hash($seq) {
    my $h  = Hash->new;
    my $it = $seq->();

    my ($key, $value);
    NEXT:
    $key   = $it->();
    goto ABORT if not defined($key);
    $value = $it->();
    goto ABORT if not defined($value);
    $h->{$key} = $value;
    goto NEXT;

    ABORT:
    return $h;
}

# to_hash : Seq<'a> -> ('a -> string,'b) -> Hash<'b>
sub to_hash($seq, $f_map) {
    my $hash = Hash->new;
    my $it = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        my ($key, $value) = $f_map->($x);
        $hash->{$key} = $value;
    }
    return $hash;
}

# Build a hash by applying a mapping function to a value to create a
# key/value pair. The value of the hash is always an array providing
# all values for the same key
#
# to_hash_of_array: Seq<'a> -> ('a -> 'Key) -> Hash<'Key, Array<'a>>
sub to_hash_of_array($seq, $f_map) {
    my $hash = Hash->new;
    iter($seq, sub($x) {
        my ($key, $value) = $f_map->($x);
        Hash::push($hash, $key, $value);
    });
    return $hash;
}

# to_array_of_array : Seq<Seq<'a>> -> Array<Array<'a>>
sub to_array_of_array($seq) {
    my $outer = Array->new;
    iter($seq, sub($inner) {
        push @$outer, to_array($inner);
    });
    return $outer;
}

# find : Seq<'a> -> ('a -> bool) -> Option<'a>
sub find($seq, $predicate) {
    my $it = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        return Option::Some($x) if $predicate->($x);
    }
    return Option::None();
}

# any : Seq<'a> -> ('a -> bool) -> bool
sub any($seq, $predicate) {
    my $it = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        return 1 if $predicate->($x);
    }
    return 0;
}

# all : Seq<'a> -> ('a -> bool) -> bool
sub all($seq, $predicate) {
    my $it = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        return 0 if not $predicate->($x);
    }
    return 1;
}

# none : Seq<'a> -> ('a -> bool) -> bool
sub none($seq, $predicate) {
    my $it = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        return 0 if $predicate->($x);
    }
    return 1;
}

# pick : Seq<'a> -> ('a -> option<'b>) -> 'b
sub pick($seq, $f_opt) {
    my $it = $seq->();
    my ($x, $is_some, $v);
    while ( defined($x = $it->()) ) {
        my $opt = Option::Some($f_opt->($x));
        return $opt if @$opt;
    }
    return Option::None();
}

1;
