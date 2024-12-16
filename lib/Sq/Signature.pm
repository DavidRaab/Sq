package Sq::Signature;
use 5.036;
use Sq;
use Sq::Type;
use Carp ();
use Sub::Exporter -setup => {
    exports => [qw(sig sig_void)],
    groups  => {
        default => [qw(sig sig_void)],
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

sub around($func_name, $fn) {
    no strict 'refs';
    no warnings 'redefine';
    my $orig = *{$func_name}{CODE};
    *{$func_name} = sub { $fn->($orig, @_) };
    return;
}

sub sig($func_name, @types) {
    Carp::croak "sig needs at least two types" if @types < 2;
    my $return    = pop @types;
    my $arg_count = @types;
    around($func_name, sub($orig, @args) {
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

# a function that returns nothing
sub sig_void($func_name, @types) {
    Carp::croak "sig needs at least one type" if @types == 0;
    my $arg_count = @types;
    around($func_name, sub($orig, @args) {
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
        my @ret = $orig->(@args);
        Carp::croak "$func_name: Expected to be void but returned a value" if @ret > 0;
        return;
    });
    return;
}

# when a function has variable args
sub sigv      { ... }
sub sigv_void { ... }

1;