package Sq::Exporter;
use 5.036;

no strict   'refs'; ## no critic
no warnings 'once';

sub import {
    my ($pkg) = caller;
    *{"$pkg\::import"}         = \&export_import;
    *{"$pkg\::load_signature"} = \&load_signature;
    *{"$pkg\::unimport"}       = \&unimport;
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

    # Load Signature
    $own->load_signature();

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

sub load_signature($own) {
    my $signature = ${"$own\::SIGNATURE"};
    if ( $Sq::LOAD_SIGNATURE && $signature ) {
        require $signature;
    }
}

# TODO: Unimporting not quite right as it deleted the whole Type-Glob
sub unimport($own, @funcs) {
    my ( $pkg ) = caller;

    if ( @funcs ) {
        for my $func ( @funcs ) {
            delete ${ $pkg . '::' }{$func};
        }
    }
    else {
        for my $func ( @{"$own\::EXPORT"} ) {
            # TODO: This is not correct
            #       This deletes the full TYPE-GLOB, but only CODE should be deleted.
            #       Theoretically i must first create a backup, and then re-install
            #       everything else that is not a function. But i don't care for those
            #       cases. The way how I write code, this problem should basically not
            #       appear at all. This can be later fixed.
            delete ${ $pkg . '::' }{$func};
        }
    }
}

1;