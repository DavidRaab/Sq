package Seq;
use 5.036;
our $VERSION = '0.001';
use List::Util qw(reduce);
use Carp qw(croak);
use DDP;

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
            if ( $abort ) {
                return undef;
            }
            else {
                ($x, $state) = $f->($state);
                $abort =1 if not defined $x;
                return $x;
            }
        }
    }, 'Seq');
}

sub init($class, $count, $f) {
    return unfold('Seq', 0, sub($index) {
        if ( $index < $count ) {
            return $f->($index), $index+1;
        }
        else {
            return undef;
        }
    });
}

sub range_step($class, $start, $step, $stop) {
    # Ascending order
    if ( $start <= $stop ) {
        return unfold('Seq', $start, sub($current) {
            if ( $current <= $stop ) {
                return $current, $current+$step;
            }
            else {
                return undef;
            }
        });
    }
    # Descending
    else {
        return unfold('Seq', $start, sub($current) {
            if ( $current >= $stop ) {
                return $current, $current-$step;
            }
            else {
                return undef;
            }
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
        if ( $idx <= $last ) {
            return $xs[$idx], $idx+1;
        }
        else {
            return undef;
        }
    });
}

# turns a list into a Seq - alias to wrap
sub from_list($class, @xs) {
    return wrap($class, @xs);
}

# turns an arrayref into a seq
sub from_array($class, $arrayref) {
    return wrap('Seq', @$arrayref);
}

# Concatenates a list of Seq into a single Seq
sub concat($class, @iters) {
    my $count = @iters;

    # with no values to concat, return an empty iterator
    if ( $count == 0 ) {
        return empty('Seq') if $#iters == -1;
    }
    # one element can be returned as-is
    elsif ( $count == 1 ) {
        return $iters[0];
    }
    # at least two
    else {
        return reduce { append($a, $b) } @iters;
    }
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

sub map($iter, $f) {
    return bless(sub {
        my $it = $iter->();
        return sub {
            if ( defined(my $x = $it->()) ) {
                return $f->($x);
            }
            else {
                return undef;
            }
        }
    }, 'Seq');
}

sub filter($iter, $predicate) {
    return bless(sub {
        my $it = $iter->();
        return sub {
            while ( defined(my $x = $it->()) ) {
                if ( $predicate->($x) ) {
                    return $x;
                }
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

sub indexed($iter) {
    my $index = 0;
    return $iter->map(sub($x) {
        return [$index++, $x];
    });
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
    return fold($iter, [], sub($array, $x) {
        push @$array, $x;
    });
}

sub to_list($iter) {
    return @{ to_array($iter) };
}

sub count($iter) {
    return fold($iter, 0, sub($count, $x) { $count+1 });
}

sub sum($iter) {
    return fold($iter, 0, sub($sum, $x) { $sum + $x });
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
