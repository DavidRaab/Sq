package Sq::Exporter;
use 5.036;
use Carp ();

no strict 'refs'; ## no critic
sub import {
    my ($pkg) = caller;
    *{"$pkg\::import"} = \&export_import;
}

sub export_import($own, @args) {
    my ( $target ) = caller;

    # get our @export of current package
    my $exports = \@{"$own\::EXPORT"};

    # Export default
    if ( @args == 0 ) {
        for my $func ( @$exports ) {
            my $fn = *{"$own\::$func"}{CODE};
            Carp::croak "function '$func' does not exists. Check \@EXPORT in $own" if !defined $fn;
            *{"$target\::$func"} = $fn;
        }
    }
    else {
        my %ok = map { $_ => 1 } @$exports;
        for my $func ( @args ) {
            my $fn = *{"$own\::$func"}{CODE};
            Carp::croak "function '$func' is not in \@EXPORT" if not $ok{$func};
            Carp::croak "function '$func' does not exists. Check \@EXPORT in $own" if !defined $fn;
            *{"$target\::$func"} = $fn;
        }
    }
}

1;