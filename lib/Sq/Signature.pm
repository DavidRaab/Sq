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

sub sig($func_name, @types) {
    Carp::croak "sig needs at least one type" if @types == 0;
    my $return    = pop @types;
    my $arg_count = @types;
    my $orig      = get_func($func_name);
    set_func($func_name, sub {
        local $Carp::CarpLevel = 1;
        # check all arguments by just consider the arguments as a tuple
        t_assert(t_tuple(@types), \@_);

        # execute original function
        my $single = $orig->(@_);
        # and check return value
        t_assert($return, $single);
        return $single;
    });
    return;
}

# a function with multiple different signatures
sub sigm($func_name, @multi) {

}

# when a function has variable args
sub sigv { ... }

1;