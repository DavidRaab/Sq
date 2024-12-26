package Sq::Reflection;
use 5.036;
sub import {
    no strict 'refs';
    my ( $pkg ) = caller;
    state @funcs = qw(get_func set_func);
    for my $func ( @funcs ) {
        *{"${pkg}::$func"} = \&$func;
    }
}

# reads function from symbol table or throws error when function
# does not exists
sub get_func($func_name) {
    my $orig = \&{ $func_name };
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
    no strict   'refs';
    no warnings 'redefine';
    *{$func_name} = $new;
    return;
}

1;