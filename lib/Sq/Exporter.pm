package Sq::Exporter;
use 5.036;
use Carp ();

no strict   'refs'; ## no critic
no warnings 'once';

sub import {
    my ($pkg) = caller;
    *{"$pkg\::import"} = \&export_import;
}

sub export_import($own, @args) {
    my ( $target ) = caller;

    # get our @export of current package
    my $exports   = \@{"$own\::EXPORT"};
    # get signature
    my $signature = ${"$own\::SIGNATURE"};

    # Build a list of options and commands that should be exported
    my %opt;
    my @cmds;
    my $idx = 0;
    while ( $idx < @args ) {
        my $current = $args[$idx];
        if ( substr($current, 0, 1) eq '-' ) {
            $opt{$current} = $args[$idx+1];
            $idx += 2;
        }
        else {
            push @cmds, $current;
            $idx++;
        }
    }

    # Load default signature when -sig => 1 is provided and $SIGNATURE
    # is defined in module
    if ( $opt{-sig} && defined $signature ) {
        local $@;
        eval { require $signature };
        Carp::croak $@ if $@;
    }

    # Export default
    if ( @cmds == 0 ) {
        for my $func ( @$exports ) {
            my $fn = *{"$own\::$func"}{CODE};
            Carp::croak "function '$func' does not exists. Check \@EXPORT in $own" if !defined $fn;
            *{"$target\::$func"} = $fn;
        }
    }
    # Export requested
    else {
        my %ok = map { $_ => 1 } @$exports;
        for my $func ( @cmds ) {
            my $fn = *{"$own\::$func"}{CODE};
            Carp::croak "function '$func' is not in \@EXPORT" if not $ok{$func};
            Carp::croak "function '$func' does not exists. Check \@EXPORT in $own" if !defined $fn;
            *{"$target\::$func"} = $fn;
        }
    }
}

1;