package Sq::Reflection;
use 5.036;
use Carp ();
# sub import {
#     no strict 'refs';
#     my ( $pkg ) = caller;
#     state @funcs = qw(get_func set_func all_funcs);
#     for my $func ( @funcs ) {
#         *{"${pkg}::$func"} = \&$func;
#     }
#     return;
# }

{
    no strict   'refs';     ## no critic
    no warnings 'redefine';

    # reads function from symbol table or throws error when function
    # does not exists
    sub get_func($func_name) {
        my $orig = *{$func_name}{CODE};
        if ( !defined $orig ) {
            my $msg =
                "Function \"$func_name\" could not be found. "
                . "Either you forgot to load a module or you have a typo.";
            Carp::croak $msg;
        }
        return $orig;
    }

    # sets function in symbol table to a new function
    sub set_func($func_name, $new) {
        *{$func_name} = $new;
        return;
    }

    # returns all functions of a package
    my %invalid = map { $_ => 1 }
            qw(__ANON__ BEGIN END INIT CHECK UNITCHECK a b import);
    sub all_funcs($package) {
        my @funcs;
        # Traverse symbol-table
        for my ($key,$glob) ( %{*{$package . '::'}} ) {
            if ( defined *{$glob}{CODE} ) {
                next if $invalid{$key};
                push @funcs, $key;
            }
        }
        return @funcs;
    }

    sub has_func($pkg, $name) {
        return 1 if defined *{"$pkg\::$name"}{CODE};
        return 0;
    }
}


1;