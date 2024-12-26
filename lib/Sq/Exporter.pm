package Sq::Exporter;
use 5.036;
use Sq::Reflection;
no strict 'refs'; ## no critic
sub import {
    my ($pkg) = caller;
    *{$pkg . '::' . 'import'} = \&export_import;
}

sub export_import($own, @args) {
    my %opt;
    my @requested;

    # process input. put key => value where key starts with `-` into
    # %opt. All other things into @requested
    my $idx = 0;
    while ( $idx < @args ) {
        my $name = $args[$idx];
        if ( substr($name, 0, 1) eq '-' ) {
            $opt{$name} = $args[$idx+1];
            $idx += 2;
        }
        else {
            push @requested, $name;
            $idx++;
        }
    }

    # Export functions into target defined with '-as'
    if ( defined $opt{-as} ) {
        my $target = $opt{-as};

        # when no function requested then just export all functions in current
        # package into target package
        if ( @requested == 0 ) {
            for my $func ( Sq::Reflection::all_funcs($own) ) {
                *{$target . '::' . $func} = \&{$own . '::' . $func};
            }
        }
        # otherwise just export requested
        else {
            for my $func ( @requested ) {
                *{$target . '::' . $func} = \&{$own . '::' . $func};
            }
        }
    }
    return;
}

1;