package Seq;
use 5.036;
our $VERSION = '0.001';
use subs 'bind', 'join', 'select';
use Scalar::Util qw(reftype);
use List::Util qw(reduce);
use Carp qw(croak);
use DDP;

# TODO: contains?, firstIndex?, mapX, reduce?, sort,
#       interspers, slice, zip, unzip, foldBack, any,
#       forall, none, max, max_by, min, min_by, average, average_by,
#       pairwise, windowed, transpose, item, chunk_by_size,
#       cartesian, one, minmax, minmax_by

# id function
my $id = sub($x) { return $x };

#- Constructurs
#    Those are functions that create Seq types

sub empty($class) {
    return bless(sub {
        return sub {
            return undef;
        }
    }, 'Seq');
}

# TODO: When $state is a reference. Same handling as in fold?
sub unfold($class, $state, $f) {
    return bless(sub {
        # Important: Perl signatures are aliases. As we assign
        # to $state later, we need to make a copy here.
        my $state = $state;
        my $abort = 0;
        my $x;
        return sub {
            return undef if $abort;

            ($x, $state) = $f->($state);
            $abort =1 if not defined $x;
            return $x;
        }
    }, 'Seq');
}

sub init($class, $count, $f) {
    return unfold('Seq', 0, sub($index) {
        return $f->($index), $index+1 if $index < $count;
        return undef;
    });
}

sub range_step($class, $start, $step, $stop) {
    croak '$step is 0. Will run forever.' if $step == 0;

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

sub range($class, $start, $stop) {
    return range_step('Seq', $start, 1, $stop);
}

# turns all arguments into an sequence
sub wrap($class, @xs) {
    my $last = $#xs;
    return unfold('Seq', 0, sub($idx) {
        return $xs[$idx], $idx+1 if $idx <= $last;
        return undef;
    });
}

# turns a list into a Seq - alias to wrap
sub from_list($class, @xs) {
    return wrap($class, @xs);
}

# turns an arrayref into a seq
sub from_array($class, $xs) {
    return unfold('Seq', 0, sub($idx) {
        return $xs->[$idx], $idx+1 if $idx <= $xs->$#*;
        return undef;
    });
}

sub from_hash($class, $hashref, $f) {
    return bless(sub {
        my $idx  = 0;
        my @keys = keys %$hashref;
        my $last = $#keys;
        return sub {
            return undef if $idx > $last;
            my $key = $keys[$idx++];
            return $f->($key, $hashref->{$key});
        }
    }, 'Seq');
}

# Concatenates a list of Seq into a single Seq
sub concat($class, @iters) {
    my $count = @iters;

    # with no values to concat, return an empty iterator
    return empty('Seq') if $count == 0;
    # one element can be returned as-is
    return $iters[0]    if $count == 1;
    # at least two items
    return reduce { append($a, $b) } @iters;
}

#- Methods
#    functions operating on Seq and returning another Seq

sub append($iterA, $iterB) {
    return bless(sub {
        my $exhaustedA = 0;
        my $itA = $iterA->();
        my $itB = $iterB->();

        return sub {
            REDO:
            if ( $exhaustedA ) {
                return $itB->();
            }
            else {
                if ( defined(my $x = $itA->()) ) {
                    return $x;
                }
                else {
                    $exhaustedA = 1;
                    goto REDO;
                }
            }
        };
    }, 'Seq');
}

# map : Seq<'a> -> ('a -> 'b) -> Seq<'b'>
sub map($iter, $f) {
    return bless(sub {
        my $it = $iter->();
        return sub {
            if ( defined(my $x = $it->()) ) {
                return $f->($x);
            }
            return undef;
        }
    }, 'Seq');
}

# bind : Seq<'a> -> ('a -> Seq<'b>) -> Seq<'b>
sub bind($iter, $f) {
    return bless(sub {
        my $it   = $iter->();
        my $seqB = undef;

        return sub {
            REDO:
            # when $seqB is defined. an entry from the seq is returned
            if ( defined $seqB ) {
                if ( defined(my $b = $seqB->()) ) {
                    return $b;
                }
                # as soon an undef is returned, $seqB finished
                $seqB = undef;
            }
            # when $seqB is undef, we request/create a new $seqB
            if ( defined(my $a = $it->()) ) {
                $seqB = $f->($a)->();
                goto REDO;
            }
            # when $seqB is not defined and $it does not return new values
            return undef;
        }
    }, 'Seq');
}

# flatten : Seq<Seq<'a>> -> Seq<'a>
sub flatten($iter) {
    return bind($iter, $id);
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
        return wrap('Seq', [$a, $b]) if $predicate->($a, $b);
        return empty('Seq');
    })});
}

# Expects a sequence of tuples. For example what join returns.
# Provides a merging function to combine 'a and 'b into something new 'c
# merge : Seq<'a * 'b> -> ('a -> 'b -> 'c) -> Seq<'c>
sub merge($iter, $merge) {
    bind($iter, sub($tuple) {
        my ($a, $b) = @$tuple;
        my $c = $merge->($a, $b);
        return wrap('Seq', $c);
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
sub select($iter, $mapA, $mapB) {
    # Transforms the different inputs a user can give into a
    # hash and an array containing the keys
    state $gen_input = sub($mapping) {
        my $hash;
        my $keys;
        if ( not defined reftype $mapping) {
            if ( $mapping =~ m/\Aall\z/i ) {
                return ['ALL'];
            }
            elsif ( $mapping =~ m/\Anone\z/i ) {
                return ['NONE'];
            }
            else {
                croak "When not arrayref or hashref must be either 'ALL' or 'NONE'";
            }
        }
        elsif ( reftype $mapping eq 'HASH' ) {
            $hash = $mapping;
            $keys = [ keys $mapping->%* ];
        }
        elsif ( reftype $mapping eq 'ARRAY' ) {
            $hash = { map { $_ => $_ } @$mapping };
            $keys = $mapping;
        }
        else {
            croak '$mappings must be tuple and either contain hashref or arrayref';
        }

        # Returns a discriminated union with three cases
        # ['ALL']
        # ['NONE']
        # ['SELECTION', $mapping, $keys]
        return [SELECTION => $hash, $keys];
    };

    my $caseA = $gen_input->($mapA);
    my $caseB = $gen_input->($mapB);

    merge($iter, sub($a, $b) {
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
sub choose($iter, $chooser) {
    return bless(sub {
        my $it = $iter->();
        return sub {
            SKIP:
            if ( defined(my $x = $it->()) ) {
                my $opt = $chooser->($x);
                return $opt if defined $opt;
                goto SKIP;
            }
            return undef;
        }
    }, 'Seq');
}

sub mapi($iter, $f) {
    return indexed($iter)->map($f);
}

sub filter($iter, $predicate) {
    return bless(sub {
        my $it = $iter->();
        return sub {
            while ( defined(my $x = $it->()) ) {
                return $x if $predicate->($x);
            }
            return undef;
        }
    }, 'Seq');
}

sub take($iter, $amount) {
    return bless(sub {
        my $i             = $iter->();
        my $returnedSoFar = 0;
        return sub {
            if ( $returnedSoFar < $amount ) {
                $returnedSoFar++;
                if ( defined(my $x = $i->()) ) {
                    return $x;
                }
            }
            return;
        }
    }, 'Seq');
}

sub skip($iter, $amount) {
    return bless(sub {
        my $it = $iter->();
        my $count = 0;
        return sub {
            while ( $count++ < $amount ) {
                $it->();
            }
            return $it->();
        }
    }, 'Seq');
}

sub indexed($iter) {
    my $index = 0;
    return $iter->map(sub($x) {
        return [$index++, $x];
    });
}

sub distinct_by($iter, $f) {
    return bless(sub {
        my $it = $iter->();
        my %seen;
        return sub {
            SKIP:
            if ( defined(my $x = $it->()) ) {
                my $key = $f->($x);
                goto SKIP if exists $seen{$key};
                $seen{$key} = 1;
                return $x;
            }
            return undef;
        }
    }, 'Seq');
}

# remove duplicates - it uses a hash to remember seen items
# so it only works good when Seq contains Strings or Numbers.
# Use distinct_by for other data.
sub distinct($iter) {
    return distinct_by($iter, $id);
}

#- Side-Effects
#    functions that have side-effects or produce side-effects. Those are
#    immediately executed, usually consuming all elements of Seq at once.

sub iter($iter, $f) {
    my $it = $iter->();
    while ( defined(my $x = $it->()) ) {
        $f->($x);
    }
    return;
}

sub rev($iter) {
    return bless(sub {
        my @list = to_list($iter);
        return sub {
            if ( defined(my $x = pop @list) ) {
                return $x;
            }
            return undef;
        };
    }, 'Seq');
}

#- Converter
#    Those are functions converting Seq to none Seq types

sub fold($iter, $state, $folder) {
    # when $state is reference, we assume $folder mutate $state
    if ( ref $state ) {
        iter($iter, sub($x) {
            $folder->($state, $x);
        });
        return $state;
    }
    # otherwise $folder returns new $state
    else {
        iter($iter, sub($x) {
            $state = $folder->($state, $x);
        });
        return $state;
    }
}

sub to_array($iter) {
    state $folder = sub($array, $x) { push @$array, $x };
    return fold($iter, [], $folder);
}

sub to_list($iter) {
    return @{ to_array($iter) };
}

sub count($iter) {
    state $folder = sub($count, $x) { $count+1 };
    return fold($iter, 0, $folder);
}

sub sum($iter) {
    state $folder = sub($sum, $x) { $sum + $x };
    return fold($iter, 0, $folder);
}

sub sum_by($iter, $f) {
    return fold($iter, 0, sub($sum, $x) {
        return $sum + $f->($x);
    });
}

sub str_join($iter, $sep) {
    return CORE::join($sep, to_list($iter));
}

# Build a hash by providing a keying function. Later elements
# in the sequence overwrite previous one.
sub to_hash($iter, $get_key) {
    my %hash;
    iter($iter, sub($x) {
        $hash{$get_key->($x)} = $x;
    });
    return \%hash;
}

# Build a hash by providing a keying function. Values
# are put into arrays to allow key with multiple values.
sub group_by($iter, $get_key) {
    my %hash;
    iter($iter, sub($x) {
        push @{ $hash{$get_key->($x)} }, $x;
    });
    return \%hash;
}

sub first($iter, $predicate) {
    my $it = $iter->();
    while ( defined(my $x = $it->()) ) {
        return $x if $predicate->($x);
    }
    return;
}

=head1 NAME

Seq - The great new Seq!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Seq;

    my $foo = Seq->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=head1 AUTHOR

David Raab, C<< <davidraab83 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-seq at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Seq>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Seq


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Seq>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Seq>

=item * Search CPAN

L<https://metacpan.org/release/Seq>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by David Raab.

This is free software, licensed under:

  The MIT (X11) License


=cut

1; # End of Seq
