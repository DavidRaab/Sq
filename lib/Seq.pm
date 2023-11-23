package Seq;
use 5.036;
our $VERSION = '0.005';
use subs 'bind', 'join', 'select', 'last', 'sort';
use Scalar::Util;
use List::Util;
use Carp;
use Sub::Exporter -setup => {
    exports => [
        qw(id fst snd key assign),
    ],
};

# TODO:
#       cache, chain, any, all, none
#       regex_match, regex_replace
#       foldBack, average, average_by,
#       pairwise, windowed, transpose, chunk_by_size, unzip
#       transpose, intesperse, slice
#       minmax, minmax_by,
#       scan, mapFold, except/exclude, pick
#       takeWhile, skipWhile, splitInto
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

# Important functions used in FP code. So adding them.
sub id  :prototype($) { return $_[0]    }
sub fst :prototype($) { return $_[0][0] }
sub snd :prototype($) { return $_[0][1] }

# a helper to create a function for selecting a hash-key
sub key :prototype($) {
    my $name = $_[0];
    return sub($hash) { return $hash->{$name} };
}

# allows writing a code block to create a value
sub assign :prototype(&) {
    return $_[0]->();
}



#-----------------------------------------------------------------------------#
# CONSTRUCTORS                                                                #
#                    Functions that create sequences                          #
#-----------------------------------------------------------------------------#

# creates a sequence from a subroutine
sub from_sub($class, $f) {
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

# always an empty sequence
sub empty($class) {
    return from_sub('Seq', sub {
        return sub { undef };
    });
}

# TODO: When $state is a reference. Same handling as in fold?
#
# Seq->unfold : 'State -> ('State -> Option<list<'a,'State>>) -> Seq<'a>
sub unfold($class, $state, $f) {
    from_sub('Seq', sub {
        # IMPORTANT: Perl signatures are aliases. As we assign
        # to $state later, we need to make a copy here.
        # Removing this lines causes bugs.
        my $state = $state;
        my $x;
        return sub {
            ($x, $state) = $f->($state);
            return $x;
        }
    });
}

# Seq->init : int -> (int -> 'a) -> Seq<'a>
sub init($class, $count, $f) {
    return unfold('Seq', 0, sub($index) {
        return $f->($index), $index+1 if $index < $count;
        return undef;
    });
}

# Seq->range_step : float -> float -> float -> Seq<float>
sub range_step($class, $start, $step, $stop) {
    Carp::croak '$step is 0. Will run forever.' if $step == 0;

    # Ascending order
    if ( $start <= $stop ) {
        return unfold('Seq', $start, sub($current) {
            return $current, $current+$step if $current <= $stop;
            return undef;
        });
    }
    # Descending
    else {
        return unfold('Seq', $start, sub($current) {
            return $current, $current-$step if $current >= $stop;
            return undef;
        });
    }
}

# Seq->range : int -> int -> Seq<int>
sub range($class, $start, $stop) {
    return range_step('Seq', $start, 1, $stop);
}

# turns all arguments into an sequence
# Seq->wrap : List<'a> -> Seq<'a>
sub wrap($class, @xs) {
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

# turns a list into a Seq - alias to wrap
# Seq->from_list : List<'a> -> Seq<'a>
sub from_list($class, @xs) {
    return wrap(Seq => @xs);
}

# turns an arrayref into a seq
# Seq->from_array : Array<'a> -> Seq<'a>
sub from_array($class, $xs) {
    return unfold('Seq', 0, sub($idx) {
        return $xs->[$idx], $idx+1;
    });
}

# Pass it a hashref. The function $f is executed for every
# (key, value) pair. The result is used as a single item in
# the sequence.
#
# Seq->from_hash : Hash<'Key, 'Value> -> ('Key -> 'Value -> 'a) -> Seq<'a>
sub from_hash($class, $hashref, $f) {
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

# Concatenates a list of Seq into a single Seq
# Seq->concat : List<Seq<'a>> -> Seq<'a>
sub concat($class, @seqs) {
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
    from_sub('Seq', sub {
        my $it = $seq->();
        my $x;
        return sub {
            if ( defined($x = $it->()) ) {
                return $f->($x);
            }
            return undef;
        }
    });
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
    return bind($seq, \&id);
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
        wrap('Seq', [$a, $b]);
    })});
}

# join creates the cartesian product, but only for those elements
# $predicate returns true.
# join : Seq<'a> -> Seq<'b> -> ('a -> 'b -> bool) -> Seq<'a * 'b>
sub join($seqA, $seqB, $predicate) {
    bind($seqA, sub($a) {
    bind($seqB, sub($b) {
        return wrap(Seq => [$a, $b]) if $predicate->($a, $b);
        return empty('Seq');
    })});
}

# Expects a sequence of tuples. For example what join returns.
# Provides a merging function to combine 'a and 'b into something new 'c
# merge : Seq<'a * 'b> -> ('a -> 'b -> 'c) -> Seq<'c>
sub merge($seq, $merge) {
    bind($seq, sub($tuple) {
        return wrap(Seq => $merge->($tuple->[0], $tuple->[1]));
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

# combines map and filter
sub choose($seq, $chooser) {
    from_sub('Seq', sub {
        my $it = $seq->();
        my ($x, $optional);
        return sub {
            while ( defined($x = $it->()) ) {
                $optional = $chooser->($x);
                return $optional if defined $optional;
            }
            return undef;
        }
    });
}

sub mapi($seq, $f) {
    return Seq::map(indexed($seq), $f);
}

sub filter($seq, $predicate) {
    from_sub('Seq', sub {
        my $it = $seq->();
        my $x;
        return sub {
            while ( defined($x = $it->()) ) {
                return $x if $predicate->($x);
            }
            return undef;
        }
    });
}

sub take($seq, $amount) {
    from_sub('Seq', sub {
        my $i             = $seq->();
        my $returnedSoFar = 0;
        my $x;
        return sub {
            return $i->() if $returnedSoFar++ < $amount;
            return undef;
        }
    });
}

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

sub indexed($seq) {
    my $index = 0;
    return Seq::map($seq, sub($x) {
        return [$index++, $x];
    });
}

sub distinct_by($seq, $f) {
    from_sub('Seq', sub {
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

# remove duplicates - it uses a hash to remember seen items
# so it only works good when Seq contains Strings or Numbers.
# Use distinct_by for other data.
sub distinct($seq) {
    return distinct_by($seq, \&id);
}

# TODO: Instead of fsts and snds provide a function to pick the index of an array.
#       Maybe even a function to pick and re-order multiple elements
#         Like: ->pick([3,1,5])

sub fsts($seq) {
    return Seq::map($seq, sub ($x) { $x->[0] });
}

sub snds($seq) {
    return Seq::map($seq, sub ($x) { $x->[1] });
}

# TODO: zip can handle a list of sequences
sub zip($seqA, $seqB) {
    from_sub('Seq', sub {
        my $itA = $seqA->();
        my $itB = $seqB->();
        my ($a, $b);

        return sub {
            if (defined ($a = $itA->())) {
            if (defined ($b = $itB->())) {
                    return [$a,$b];
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
            CORE::map  { [$get_key->($_), $_] } @$array;

        return sub {
            return $sorted[$idx++];
        }
    });
}

# group_by : Seq<'a> -> ('a -> 'Key) -> Seq<Seq<'a>>
sub group_by($seq, $get_key) {
    my %group;
    iter($seq, sub($a) {
        my $key = $get_key->($a);
        push $group{$key}->@*, $a;
    });

    return from_hash('Seq', \%group, sub($key, $value) {
        return from_array('Seq', $value);
    });
}

# group_fold :
#   Seq<'a>
#   -> (unit -> 'State)
#   -> ('a -> 'Key)
#   -> ('State -> 'a -> 'State)
#   -> Seq<'State>
sub group_fold($seq, $get_state, $get_key, $folder) {
    my %group;
    iter($seq, sub($a) {
        my $key = $get_key->($a);
        push $group{$key}->@*, $a;
    });

    return from_hash('Seq', \%group, sub($key, $array) {
        my $state = $get_state->();
        for my $a ( @$array ) {
            $state = $folder->($state, $a);
        }
        return $state;
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

# Similar to iter(). But returns the $seq as-is.
# Useful for doing something between a chain. For example printing
# all elements of a sequence.
#
# $seq->do(sub($x) { print Dumper($x) })->...
sub do($seq, $f) {
    my $it = $seq->();
    my $x;
    $f->($x) while defined($x = $it->());
    return $seq;
}



#----------------------------------------------------------------------#
# CONVERTER                                                            #
#         Those are functions converting Seq to none Seq types         #
#----------------------------------------------------------------------#

# fold is like a foreach-loop. You iterate through all items generating
# a new 'State. The $folder is passed the latest
# 'State and one 'a from the sequence. You return
# the next 'State that should be used. Once all elements of 'a
# sequence are processed. The last 'State is returned.
#
# fold : Seq<'a> -> 'State -> ('State -> 'a -> 'State) -> 'State
sub fold($seq, $state, $folder) {
    iter($seq, sub($x) {
        $state = $folder->($state, $x);
    });
    return $state;
}

# Same as fold. But when you mutate 'State and return 'State from
# the lambda. You can use this function instead.
#
# fold : Seq<'a> -> 'State -> ('State -> 'a -> 'State) -> 'State
sub fold_mut($seq, $state, $folder) {
    iter($seq, sub($x) {
        $folder->($state, $x);
    });
    return $state;
}

# Like fold, but without an initial state. When sequence is empty
# it returns an undef. Otherwise combines two elements from
# left to right to produce an output. Needs a sequence
# with one item to work properly. It is encouraged to use `fold`
# instead.
# reduce: Seq<'a> -> ('a -> 'a -> 'a) -> 'a
sub reduce($seq, $reducer, $default) {
    return fold(skip($seq, 1), first($seq, $default), $reducer);
}

# first : Seq<'a> -> 'a -> 'a
sub first($seq, $default) {
    my $first = $seq->()();
    return defined $first ? $first : $default;
}

# last : Seq<'a> -> 'a -> 'a
sub last($seq, $default) {
    my $last;
    iter($seq, sub($x) {
        $last = $x;
    });
    return defined $last ? $last : $default;
}

# to_array : Seq<'a> -> Array<'a>
sub to_array($seq) {
    state $folder = sub($array, $x) { push @$array, $x };
    return fold_mut($seq, [], $folder);
}

sub to_list($seq) {
    return @{ to_array($seq) };
}

# count : Seq<'a> -> int
sub count($seq) {
    state $folder = sub($count, $x) { $count+1 };
    return fold($seq, 0, $folder);
}

# sum : Seq<'a> -> float
sub sum($seq) {
    state $folder = sub($sum, $x) { $sum + $x };
    return fold($seq, 0, $folder);
}

# sum_by : Seq<'a> -> (float -> 'a -> float) -> float
sub sum_by($seq, $f) {
    return fold($seq, 0, sub($sum, $x) {
        return $sum + $f->($x);
    });
}

# returns the min value or undef on empty sequence
# min value is compared with numerical <
sub min($seq, $default) {
    min_by($seq, \&id, $default);
}

sub min_by($seq, $key, $default) {
    return fold($seq, undef, sub($min, $x) {
        my $value = $key->($x);
        defined $min
            ? ($value < $min) ? $value : $min
            : $value;
    }) // $default;
}

# returns the min value or undef on empty sequence
# min value is compared using lt
sub min_str($seq, $default) {
    min_str_by($seq, \&id, $default);
}

sub min_str_by($seq, $key, $default) {
    return fold($seq, undef, sub($min, $x) {
        my $value = $key->($x);
        defined $min
            ? ($value lt $min) ? $value : $min
            : $value;
    }) // $default;
}

# returns the max value or undef when sequence is empty
sub max($seq, $default) {
    max_by($seq, \&id, $default);
}

sub max_by($seq, $key, $default) {
    return fold($seq, undef, sub($max, $x) {
        my $value = $key->($x);
        defined $max
            ? ($value > $max) ? $value : $max
            : $value;
    }) // $default;
}

sub max_str($seq, $default) {
    max_str_by($seq, \&id, $default);
}

sub max_str_by($seq, $key, $default) {
    return fold($seq, undef, sub($max, $x) {
        my $value = $key->($x);
        defined $max
            ? ($value gt $max) ? $value : $max
            : $value;
    }) // $default;
}

sub str_join($seq, $sep) {
    return CORE::join($sep, to_list($seq));
}

# Build a hash by providing a keying function. Later elements
# in the sequence overwrite previous one.
sub to_hash($seq, $get_key) {
    my %hash;
    iter($seq, sub($x) {
        $hash{$get_key->($x)} = $x;
    });
    return \%hash;
}

# Build a hash by providing a keying function. Values
# are put into arrays to allow key with multiple values.
#
# to_hash_of_array: Seq<'a> -> ('a -> 'Key) -> Hash<'Key, Array<'a>>
sub to_hash_of_array($seq, $get_key) {
    my %hash;
    iter($seq, sub($x) {
        push @{ $hash{$get_key->($x)} }, $x;
    });
    return \%hash;
}

# to_array_of_array : Seq<Seq<'a>> -> Array<Array<'a>>
sub to_array_of_array($seq) {
    my @outer;
    iter($seq, sub($inner) {
        push @outer, to_array($inner);
    });
    return \@outer;
}

# returns first element for which the given $predicate returns true
#
# find : Seq<'a> -> ('a -> bool) -> 'a
sub find($seq, $default, $predicate) {
    my $it = $seq->();
    my $x;
    while ( defined($x = $it->()) ) {
        return $x if $predicate->($x);
    }
    return $default;
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

1;
