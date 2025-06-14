package Sq::Collections::Seq;
package Seq;
use 5.036;
use subs 'bind', 'join', 'select', 'last', 'sort', 'map', 'length';

# TODO:
#       Find another name for 'from_list'
#       chain
#       extract(predicate, predicate)
#       foldBack, average, average_by,
#       unzip, transpose
#       minmax, minmax_by,
#       scan, mapFold, except/exclude
#       splitInto
#     ? contains, firstIndex, mapX, on
#
# + more ways to transform data, especially complex structures
# ? A data transformation/selection language
# o Maybe DU, Record fist-class support when i implement them.
# o good way to also implement async with it?

#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create sequences                          #
#-----------------------------------------------------------------------------#

# creates a sequence from a subroutine. It already implements the logic
# that when the subroutine returns "undef" once. The sequence correctly
# aborts and free the iterator. Otherwise this function also can be used
# as a Template for every new sequence implementation. As this must be
# the default for sequences.
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

sub one($, $x) {
    bless(sub {
        my $abort = 0;
        return sub {
            return undef if $abort;
            $abort = 1;
            return $x;
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
    bless(sub {
        my $abort  = 0;
        my $amount = 0;
        return sub {
            return undef if $abort;
            return $initial if ++$amount <= $count;
            $abort = 1;
            return undef;
        }
    }, 'Seq');
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
        my $x;
        return sub {
            return undef if $abort;
            if ( $current < $count ) {
                $x = $f->($current++);
                return $x if defined $x;
            }
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

sub up($, $start) {
    return bless(sub {
        my $current = $start;
        return sub { $current++ }
    }, 'Seq');
}

sub down($, $start) {
    return bless(sub {
        my $current = $start;
        return sub { $current-- }
    }, 'Seq');
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
    return empty('Seq')  if $count == 0;
    # one element can be returned as-is
    return $seqs[0]      if $count == 1;
    # exactly two, just use append
    return append(@seqs) if $count == 2;

    return bless(sub {
        my $abort = 0;
        my $idx   = 0;
        my $it    = $seqs[0]->();
        my $x;
        return sub {
            return undef if $abort;
            REDO:
            $x = $it->();
            return $x if defined $x;

            undef $it;
            if ( ++$idx < $count ) {
                $it = $seqs[$idx]->();
                goto REDO;
            }
            $abort = 1;
            undef $it;
        }
    }, 'Seq');
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
    bless(sub {
        my $abort      = 0;
        my $exhaustedA = 0;
        my $itA        = $seqA->();
        my $itB;
        my $x;

        return sub {
            return undef if $abort;
            REDO:
            if ( $exhaustedA ) {
                $x = $itB->();
                return $x if defined $x;
                $abort = 1;
                undef $itB;
            }
            else {
                $x = $itA->();
                return $x if defined $x;
                undef $itA;
                $exhaustedA = 1;
                $itB = $seqB->();
                goto REDO;
            }
        };
    }, 'Seq');
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

sub map3($seqA, $seqB, $seqC, $f) {
    return bless(sub {
        my $abort = 0;
        my $itA = $seqA->();
        my $itB = $seqB->();
        my $itC = $seqC->();
        my ($a,$b,$c);
        return sub {
            return undef if $abort;
            if ( defined($a = $itA->()) ) {
            if ( defined($b = $itB->()) ) {
            if ( defined($c = $itC->()) ) {
                return $f->($a,$b,$c);
            }}}
            $abort = 1;
            undef $itA;
            undef $itB;
            undef $itC;
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

# merge : Seq<Array<'a>> -> Seq<'a>
sub merge($seq) {
    return bind($seq, sub($array) {
        return from_array('Seq', $array);
    });
}

sub cartesian(@seqs) {
    return bless(sub {
        my $abort = 0;
        my @its   = map { $_->() } @seqs;
        my $last  = @its - 1;
        my @values;
        return sub {
            return undef if $abort;
            # first call
            if ( @values == 0 ) {
                @values = map { $_->() } @its;
                # TODO:
                # When one sequence is empty i just abort. Another idea would be
                # to skip empty sequences. But then the behaviour should be the
                # same in an Array::cartesian
                if ( grep { !defined } @values ) {
                    $abort = 1;
                    return undef;
                }
                return bless([@values], 'Array');
            }
            # all others
            else {
                my $idx = $last;
                UP:
                my $x = $its[$idx]->();
                # when last iterator returns new element we save new value
                # and can immediately return
                if ( defined $x ) {
                    $values[$idx] = $x;
                    return bless([@values], 'Array');
                }
                # last/current iterator ended
                else {
                    # re-initalize current iterator again, and get first value again
                    # current starts being last, but the loop maybe needs to
                    # reset multiple iterators again.
                    $its[$idx]    = $seqs[$idx]->();
                    $values[$idx] = $its[$idx]->();
                    $idx--;
                    # when we reach -1 then the sequence ends
                    if ( $idx < 0 ) {
                        $abort = 1;
                        undef @its;
                        undef @values;
                        return undef;
                    }
                    # we now try previous $idx and loop
                    else {
                        goto UP;
                    }
                }
            }
        }
    }, 'Seq');
}

# join creates the cartesian product, but only for those elements
# $predicate returns true.
# join : Seq<'a> -> Seq<'b> -> ('a -> 'b -> bool) -> Seq<'a * 'b>
sub left_join($seqA, $seqB, $predicate) {
    bind($seqA, sub($a) {
    bind($seqB, sub($b) {
        return new (Seq => [$a, $b]) if $predicate->($a, $b);
        return empty('Seq');
    })});
}

# Expects a sequence of tuples. For example what join returns.
# Provides a merging function to combine 'a and 'b into something new 'c
# merge : Seq<'a * 'b> -> ('a -> 'b -> 'c) -> Seq<'c>
# sub merge($seq, $merge) {
#     bind($seq, sub($array) {
#         return new (Seq => $merge->(@$merge));
#     });
# }

# Merges a sequence that contains tuples with hashes. Like: [{...}, {...}]
# $mapA contains the selection from the first element of the tuple
# $mapB contains the selection from the second element of the tuple
#
# Selection can either be a hashref mapping a hashnames to a
# new hashname { id => 'some_id' }
#
# or an array of names that should be picked: [qw/id name/]
#
# TODO: Because i changed merge this doesn't work anymore. But I anyway
#       didn't liked that stuff. API & code is too complex.
#       Just commented it, to remind me to either do something with it. And
#       extract some useful ideas from it. Or remove in the future.
#
# sub select($seq, $mapA, $mapB) {
#     # Transforms the different inputs a user can give into a
#     # hash and an array containing the keys
#     state $gen_input = sub($mapping) {
#         my $hash;
#         my $keys;
#         if ( !defined Scalar::Util::reftype($mapping) ) {
#             if ( $mapping =~ m/\Aall\z/i ) {
#                 return ['ALL'];
#             }
#             elsif ( $mapping =~ m/\Anone\z/i ) {
#                 return ['NONE'];
#             }
#             else {
#                 Carp::croak "When not arrayref or hashref must be either 'ALL' or 'NONE'";
#             }
#         }
#         elsif ( Scalar::Util::reftype($mapping) eq 'HASH' ) {
#             $hash = $mapping;
#             $keys = [ keys $mapping->%* ];
#         }
#         elsif ( Scalar::Util::reftype($mapping) eq 'ARRAY' ) {
#             $hash = { map { $_ => $_ } @$mapping };
#             $keys = $mapping;
#         }
#         else {
#             Carp::croak '$mappings must be tuple and either contain hashref or arrayref';
#         }

#         # Returns a discriminated union with three cases
#         # ['ALL']
#         # ['NONE']
#         # ['SELECTION', $mapping, $keys]
#         return [SELECTION => $hash, $keys];
#     };

#     my $caseA = $gen_input->($mapA);
#     my $caseB = $gen_input->($mapB);

#     merge($seq, sub($a, $b) {
#         my %new_hash;

#         # Merge keys from $seqA
#         if ( $caseA->[0] eq 'ALL' ) {
#             # Copies hash
#             %new_hash = %$a;
#         }
#         elsif ( $caseA->[0] eq 'NONE' ) {
#             # do nothing here ...
#         }
#         else {
#             my ($mapping, $keys) = $caseA->@[1,2];
#             for my $key ( @$keys ) {
#                 $new_hash{$mapping->{$key}} = $a->{$key};
#             }
#         }

#         # Merge keys from $seqB
#         if ( $caseB->[0] eq 'ALL' ) {
#             # add keys from $b to new hash
#             for my $key ( keys %$b ) {
#                 $new_hash{$key} = $b->{$key};
#             }
#         }
#         elsif ( $caseB->[0] eq 'NONE' ) {
#             # do nothing here ...
#         }
#         else {
#             my ($mapping, $keys) = $caseB->@[1,2];
#             for my $key ( @$keys ) {
#                 $new_hash{$mapping->{$key}} = $b->{$key};
#             }
#         }

#         return \%new_hash;
#     });
# }

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

# keep : Seq<'a> -> ('a -> bool) -> Seq<'a>
sub keep($seq, $predicate) {
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

sub remove($seq, $predicate) {
    return bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my $x;
        return sub {
            return undef if $abort;
            while ( defined($x = $it->()) ) {
                return $x if !$predicate->($x);
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
                $x = $it->();
                return $x if defined $x;
            }
            $abort = 1;
            return undef;
        }
    }, 'Seq');
}

# take_while : Seq<'a> -> ('a -> bool) -> Seq<'a>
sub take_while($seq, $predicate) {
    bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my $value;
        return sub {
            return undef if $abort;
            $value = $it->();
            return $value if $predicate->($value);
            $abort = 1;
            undef $it;
        };
    }, 'Seq');
}

# skip : Seq<'a> -> int -> Seq<'a>
sub skip($seq, $amount) {
    bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my $count = 0;
        my $x;

        while ( $count++ < $amount ) {
            $x = $it->();
            next if defined $x;
            $abort = 1;
            last;
        }

        return sub {
            return undef if $abort;
            $x = $it->();
            return $x if defined $x;
            $abort = 1;
            undef $it;
        }
    }, 'Seq');
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

sub slice($seq, @idxs) {
    return bless([], 'Array') if @idxs == 0;
    # result of slice
    my @new;
    # first we remove negative indexes
    @idxs = grep { $_ >= 0 } @idxs;
    # then a mapping 10,5,7,5,9 => { 10 => [0], 5 => [1,3], 7 => [2], 9 => [3] }
    my %mapping;
    for (my $idx=0; $idx < @idxs; $idx++) {
        push $mapping{$idxs[$idx]}->@*, $idx;
    }
    # retrieve the highest index we need to fetch from sequence
    my $max = Array::max(\@idxs, -1);
    my $it  = $seq->();
    my ($x, $dsts);
    for (my $idx=0; $idx <= $max; $idx++) {
        $x    = $it->();
        last if !defined $x;
        $dsts = $mapping{$idx};
        if ( defined $dsts ) {
            for my $dst ( @$dsts ) {
                $new[$dst] = $x;
            }
        }
    }
    # Only keep defined values. This removes indexes beyond maximum
    @new = grep { defined } @new;
    bless(\@new, 'Array');
}

# indexed : Seq<'a> -> Seq<'a * int>
sub indexed($seq) {
    my $index = 0;
    return Seq::map($seq, sub($x) {
        return bless([$x, $index++], 'Array');
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

# fsts : Seq<'a * 'b> -> Seq<'a>
sub fsts($seq) {
    return Seq::map($seq, sub ($x) { $x->[0] });
}

# snds : Seq<'a * 'b> -> Seq<'b>
sub snds($seq) {
    return Seq::map($seq, sub ($x) { $x->[1] });
}

# zip : Seq<'a> -> Seq<'b> -> Seq<'a * 'b>
sub zip(@seqs) {
    return bless(sub {
        my $abort = 0;
        my @its   = map { $_->() } @seqs;
        return sub {
            return undef if $abort;
            my (@new, $x);
            for my $it ( @its ) {
                $x = $it->();
                goto ABORT if !defined $x;
                push @new, $x;
            }
            return bless(\@new, 'Array');

            ABORT:
            $abort = 1;
            undef @its;
        }
    }, 'Seq');
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
    return Array::sort(to_array($seq), $comparer);
}

# sort_by : Seq<'a> -> ('Key -> 'Key -> int) -> ('a -> 'Key) -> Seq<'a>
sub sort_by($seq, $comparer, $get_key) {
    return Array::sort_by(to_array($seq), $comparer, $get_key);
}

sub intersect($seqA, $seqB, $f_key) {
    my @new;

    # build seen elements from $seqB
    my (%indexB, $x);
    my $it = $seqB->();
    while ( defined($x = $it->()) ) {
        $indexB{ $f_key->($x) } = 1;
    }

    # traverse $seqA and save every seen element in @new
    my $key;
    $it = $seqA->();
    while ( defined($x = $it->()) ) {
        $key = $f_key->($x);
        if ( exists $indexB{$key} ) {
            push @new, $x;
        }
    }

    return CORE::bless(\@new, 'Array');
}

sub cache($seq) {
    my $it       = $seq->();
    my $finished = 0;        # if $it finished once
    my @cache;
    return bless(sub {
        my $abort = 0;
        my $idx   = 0;
        my $x;
        return sub {
            return undef if $abort;
            # when $it finished we only need to serve from @cache
            if ( $finished ) {
                return $cache[$idx++] if $idx < @cache;
                $abort = 1;
                return undef;
            }
            # otherwise we serve from @cache or read/cache from $it
            else {
                # serve from cache when cache has item
                return $cache[$idx++] if $idx < @cache;
                # otherwise read from iterator to get next element,
                # save in cache and return.
                if ( defined($x = $it->()) ) {
                    push @cache, $x;
                    $idx++;
                    return $x;
                }
                $abort    = 1;
                $finished = 1;
                undef $it;
            }
        }
    }, 'Seq');
}

sub rx($seq, $regex) {
    return bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my $str;
        return sub {
            return undef if $abort;

            NEXT_LINE:
            if ( defined($str = $it->()) ) {
                return $str if $str =~ $regex;
                goto NEXT_LINE;
            }
            $abort = 1;
            undef $it;
        }
    }, 'Seq');
}


sub rxm($seq, $regex) {
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

sub rxs($seq, $regex, $fn) {
    from_sub(Seq => sub {
        my $it = $seq->();
        return sub {
            NEXT_LINE:
            my $str = $it->();
            return undef if not defined $str;
            $str =~ s/$regex/$fn->(@{^CAPTURE})/e;
            return $str;
        };
    });
}

sub rxsg($seq, $regex, $fn) {
    from_sub(Seq => sub {
        my $it = $seq->();
        return sub {
            NEXT_LINE:
            my $str = $it->();
            return undef if not defined $str;
            $str =~ s/$regex/$fn->(@{^CAPTURE})/ge;
            return $str;
        };
    });
}

# windowed : Seq<'a> -> int -> Seq<Array<'a>>
sub windowed($seq, $window_size) {
    return empty('Seq') if $window_size <= 0;
    return bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my @queue;

        my $x;
        for ( 1 .. $window_size ) {
            $x = $it->();
            if ( defined $x ) {
                push @queue, $x
            }
            else {
                last;
            }
        }

        # 1=first call, 2=all others
        my $state = @queue > 0 ? 1 : 2;
        return sub {
            return undef if $abort;
            if ( $state == 1 ) {
                $state = 2;
                return CORE::bless([@queue], 'Array');
            }
            else {
                $x = $it->();
                if ( defined $x ) {
                    shift @queue;
                    push @queue, $x;
                    return CORE::bless([@queue], 'Array');
                }
                else {
                    $abort = 1;
                    @queue = ();
                    undef $it;
                    return undef;
                }
            }
        }
    }, 'Seq');
}

sub chunked($seq, $size) {
    return bless(sub {
        my $abort = 0;
        my $it    = $seq->();

        return sub {
            return undef if $abort;
            my $count = 0;
            my $new   = bless([],'Array');
            ITEM:

            my $x;
            while ( defined($x = $it->()) ) {
                push @$new, $x;
                return $new if ++$count >= $size;
            }

            $abort = 1;
            undef $it;
            return @$new == 0 ? undef : $new;
        }
    }, 'Seq');
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

sub trim($seq) {
    return bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my $x;
        return sub {
            return undef if $abort;
            if ( defined($x = $it->()) ) {
                $x =~ s/\A\s+//;
                $x =~ s/\s+\z//;
                return $x;
            }
            $abort = 1;
            undef $it;
        }
    }, 'Seq');
}

sub permute($seq) {
    state $count_up = Sq->math->permute_count_up;
    return bless(sub {
        my $abort   = 0;
        my $array   = to_array($seq);
        my $pattern = [(0) x @$array];

        if ( @$array == 0 ) {
            return sub { undef }
        }
        elsif ( @$array == 1 ) {
            return sub {
                return undef if $abort;
                $abort = 1;
                return $array;
            }
        }
        else {
            return sub {
                return undef if $abort;
                my @copy = @$array;
                my @new;
                for my $idx ( @$pattern ) {
                    push @new, splice(@copy, $idx, 1);
                }
                if ( !$count_up->($pattern) ) {
                    $abort = 1;
                    undef $array;
                    undef $pattern;
                }
                return CORE::bless(\@new, 'Array');
            }
        }
    }, 'Seq');
}

sub tail($seq) { $seq->skip(1) }

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

sub itern($seq, $amount, $f) {
    Carp::croak 'Seq::itern: $amount should be at least 2' if $amount < 2;
    my $it         = $seq->();
    my ($count,$x) = (0);
    my @values;
    while ( defined($x = $it->()) ) {
        push @values, $x;
        if ( ++$count >= $amount ) {
            $f->(@values);
            @values = ();
            $count  = 0;
        }
    }
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

# Similar to iter(). But returns the $seq as-is.
# Useful for doing something between a chain. For example printing
# all elements of a sequence.
#
# $seq->do(sub($x) { print Dumper($x) })->...
#
# do : Seq<'a> -> ('a -> unit) -> Seq<'a>
sub do($seq, $f) {
    return bless(sub {
        my $abort = 0;
        my $it    = $seq->();
        my $x;
        return sub {
            return undef if $abort;
            if ( defined($x = $it->()) ) {
                $f->($x);
                return $x;
            }
            $abort = 1;
            undef $it;
            undef $x;
        }
    }, 'Seq');
}

# Same as do() but also provides an index
sub doi($seq, $f) {
    return bless(sub {
        my $abort     = 0;
        my $it        = $seq->();
        my ($idx, $x) = (0, undef);
        return sub {
            return undef if $abort;
            if ( defined($x = $it->()) ) {
                $f->($x, $idx++);
                return $x;
            }
            $abort = 1;
            undef $it;
            undef $x;
        }
    }, 'Seq');
}

sub do_every($seq, $count, $f) {
    return bless(sub {
        my $abort   = 0;
        my $it      = $seq->();
        my $idx     = 0;
        my $x;
        return sub {
            return undef if $abort;
            if ( defined($x = $it->()) ) {
                $f->($x, $idx) if $idx % $count == 0;
                $idx++;
                return $x;
            }
            $abort = 1;
            undef $it;
        }
    }, 'Seq');
}

#----------------------------------------------------------------------#
# CONVERTER                                                            #
#         Those are functions converting Seq to none Seq types         #
#----------------------------------------------------------------------#

sub is_empty($seq) {
    my $x = $seq->()();
    return defined $x ? 0 : 1;
}

sub head($seq) {
    my $x = $seq->()();
    return $x if defined $x;
    Carp::croak "Seq::head Sequence was empty";
}

sub average($seq) {
    my $sum   = 0;
    my $count = 0;
    my $it  = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        $sum += $x;
        $count++;
    }
    return $sum / $count;
}

sub average_by($seq, $f_map) {
    my $sum   = 0;
    my $count = 0;
    my $it    = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        $sum += $f_map->($x);
        $count++;
    }
    return $sum / $count;
}

# group_fold :
#   Seq<'a>
#   -> (unit -> 'State)
#   -> ('a -> 'Key)
#   -> ('State -> 'a -> 'State)
#   -> Hash<'Key,'State>
sub group_fold($seq, $get_state, $get_key, $folder) {
    my $new = Hash->empty;
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

sub keyed_by($seq, $f_key) {
    my (%hash, $key, $x);
    my $it = $seq->();
    while ( defined($x = $it->()) ) {
        $key = $f_key->($x);
        $hash{$key} = $x;
    }
    return CORE::bless(\%hash, 'Hash');
}

sub group_by($seq, $f_key) {
    my (%hash, $key, $x);
    my $it = $seq->();
    while ( defined($x = $it->()) ) {
        $key = $f_key->($x);
        push @{$hash{$key}}, $x;
    }
    # Add Array blessings
    for my $value ( CORE::values %hash ) {
        CORE::bless($value, 'Array');
    }
    return CORE::bless(\%hash, 'Hash');
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

sub contains($seq, $any) {
    my $it = $seq->();
    my $x;
    if ( Sq::is_regex($any) ) {
        while ( defined($x = $it->()) ) {
            return 1 if $x =~ $any;
        }
    }
    else {
        while ( defined($x = $it->()) ) {
            return 1 if Sq::Equality::equal($x, $any);
        }
    }
    return 0;
}

sub index($seq, $idx, $default=undef) {
    my $it            = $seq->();
    my ($current, $x) = (0);
    while ( defined($x = $it->()) ) {
        if ( $idx == $current++ ) {
            return defined $default ? $default : Option::Some($x);
        }
    }
    return defined $default ? $default : Option::None();
}

sub count($seq) {
    my (%new, $x);
    my $it = $seq->();
    while ( defined($x = $it->()) ) {
        $new{$x}++;
    }
    return bless(\%new, 'Hash');
}

sub count_by($seq, $f_map) {
    my (%new, $x);
    my $it = $seq->();
    while ( defined($x = $it->()) ) {
        $new{$f_map->($x)}++;
    }
    return bless(\%new, 'Hash');
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
    my (@new, $x);
    my $it = $seq->();
    if ( defined $count ) {
        my $current = 0;
        while ( $current++ < $count && defined($x = $it->()) ) {
            push @new, $x;
        }
    }
    else {
        while ( defined($x = $it->()) ) {
            push @new, $x;
        }
    }
    return bless(\@new, 'Array');
}

sub to_arrays($any) {
    my $type = ref $any;

    if ( $type eq 'Seq' ) {
        my (@new, $x);
        my $it = $any->();
        while ( defined($x = $it->()) ) {
            push @new, to_arrays($x);
        }
        return bless(\@new, 'Array');
    }
    elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
        return bless([map { to_arrays($_) } @$any], 'Array');
    }
    elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
        my %new;
        for my ($k,$v) ( %$any ) {
            $new{$k} = to_arrays($v);
        }
        return bless(\%new, 'Hash');
    }
    elsif ( $type eq 'Option' ) {
        return bless([map { to_arrays($_) } @$any], 'Option');
    }
    elsif ( $type eq 'Result' ) {
        return bless([$any->[0], to_arrays($any->[1])], 'Result');
    }
    else {
        return $any;
    }
}

# Copy function to Array for API Compatibility
{
    no warnings 'once';
    *Array::to_arrays = \&to_arrays;
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
sub join($seq, $sep='') {
    return CORE::join($sep, expand($seq));
}

sub split($seq, $regex) {
    return Seq::map($seq, sub($line) {
        bless([split $regex, $line], 'Array');
    });
}

sub as_hash($seq) {
    my $h  = Hash->empty;
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
    my $hash = Hash->empty;
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
    my $hash = Hash->empty;
    iter($seq, sub($x) {
        my ($key, $value) = $f_map->($x);
        Hash::push($hash, $key, $value);
    });
    return $hash;
}

# to_array_of_array : Seq<Seq<'a>> -> Array<Array<'a>>
sub to_array_of_array($seq) {
    my $outer = Array->empty;
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

sub find_windowed($seq, $amount, $predicate) {
    my (@queue, $x);
    my ($found, $it) = (0, $seq->());
    while ( defined($x = $it->()) ) {
        push @queue, $x;
        if ( $predicate->($x) ) {
            $found = 1;
            last;
        }
        shift @queue if @queue > $amount;
    }
    if ( $found ) {
        my $count = 0;
        NEXT:
        goto FINISH if $count++ >= $amount;
        $x = $it->();
        goto FINISH if !defined $x;
        push @queue, $x;
        goto NEXT;
    }
    FINISH:
    return CORE::bless([CORE::bless(\@queue, 'Array')], 'Option') if $found;
    return CORE::bless([], 'Option');
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
        return 0 if !$predicate->($x);
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
    my ($x, $opt);
    while ( defined($x = $it->()) ) {
        $opt = Option::Some($f_opt->($x));
        return $opt if @$opt;
    }
    return Option::None();
}

1;
