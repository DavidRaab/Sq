package Sq::Signature;
use 5.036;
use Sq;
use Sq::Type;
use Carp ();
use Sub::Exporter -setup => {
    exports => [qw(sig)],
    groups  => {
        default => [qw(sig)],
    },
};

# TODO:
# + Need support for varargs
# + back-reference an unknown type
# + wrap lambdas with a type-check version
# + functions with list context?
# + easy way for default args
# + define multiple signatures for one function
# + even-sized array check

# reads function from symbol table or throws error when function
# does not exists
sub get_func($func_name) {
    no strict 'refs';
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
    no strict   'refs';
    no warnings 'redefine';
    *{$func_name} = $new;
    return;
}

sub sig($func_name, @types) {
    Carp::croak "sig needs at least one type" if @types == 0;
    my $return    = pop @types;
    my $arg_count = @types;
    my $orig      = get_func($func_name);
    set_func($func_name, sub {
        my ( @args ) = @_;
        # when argument count is not correct
        if ( $arg_count != @args ) {
            Carp::croak(
                sprintf("$func_name: Arity mismatch: Expected %d arguments. Got: %d",
                    $arg_count, scalar @args)
            );
        }
        # test input parameters
        local $Carp::CarpLevel = 1;
        for (my $idx=0; $idx < $arg_count; $idx++) {
            t_assert($types[$idx], $args[$idx]);
        }
        # call original function
        my $single = $orig->(@args);
        # check return value
        t_assert($return, $single);
        return $single;
    });
    return;
}

# a function with multiple different signatures
sub sigm($func_name, @multi) {

}

# when a function has variable args
sub sigv      { ... }
sub sigv_void { ... }

1;