package Seq;
use 5.036;
our $VERSION = '0.001';

#- Constructurs
#    Those are functions that create Seq types

sub range($class, $start, $stop) {
    return bless(sub {
        my $current = $start;
        return sub {
            if ( $current <= $stop ) {
                return $current++;
            }
            else {
                undef;
            }
        }
    }, $class);
}

#- Methods
#    functions operating on Seq

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

#- Side-Effects
#    functions that have side-effects or produce side-effects. Those are
#    immediately executed.

sub iter($iter, $f) {
    my $it = $iter->();
    while ( defined(my $x = $it->()) ) {
        $f->($x);
    }
    return;
}

#- Converter
#    Those are functions converting Seq to none Seq types

sub to_array($iter) {
    my @array;

    $iter->iter(sub($x) {
        push @array, $x;
    });

    return \@array;
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
