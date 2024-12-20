package Sq::Signature;
use 5.036;
use Sq;
use Sq::Type;
use Carp ();
use Sub::Exporter -setup => {
    exports => [qw(sig sigt)],
    groups  => {
        default => [qw(sig sigt)],
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
    my $type_ret   = pop @types;
    my $arg_count  = @types;
    my $orig       = get_func($func_name);
    my $input_type = t_tuple(@types);
    set_func($func_name, sub {
        local $Carp::CarpLevel = 1;
        # check input arguments by just consider the arguments as a tuple
        t_assert($input_type, \@_);
        # execute original function
        # list context
        # if ( wantarray ) {
        #     my $ret = [$orig->(@_)];
        #     t_assert($type_ret, $ret);
        #     return @$ret;
        # }
        # # scalar context
        # else {
            my $ret = $orig->(@_);
            t_assert($type_ret, $ret);
            return $ret;
        # }
    });
    return;
}

# Tuple based function checking. Consider every function as just a function
# with a single input and output. The whole input is passed as an array and
# checked against $in_type. Output again is checked against $out_type.
# So it usually makes sense to use t_tuple for $in_type.
sub sigt($func_name, $in_type, $out_type) {
    my $orig = get_func($func_name);
    set_func($func_name, sub {
        local $Carp::CarpLevel = 1;
        t_assert($in_type, [@_]);
        my $ret = $orig->(@_);
        t_assert($out_type, $ret);
        return $ret;
    });
}

# a function with multiple different signatures
sub sigm($func_name, @multi) {

}

# when a function has variable args
sub sigv { ... }

1;