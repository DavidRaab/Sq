package Sq::Signature;
use 5.036;
use Sq;
use Sq::Type;
use Carp ();
sub import {
    no strict 'refs';
    my ( $pkg ) = caller;
    state @funcs = qw(sig sigt);
    for my $func ( @funcs ) {
        *{"${pkg}::$func"} = \&$func;
    }
}

# TODO:
# + back-reference an unknown type
# + wrap lambdas with a type-check version
# + functions with list context?
# + easier way for default args

sub sig($func_name, @types) {
    Carp::croak "sig needs at least one type" if @types == 0;
    local $Carp::CarpLevel = 1;
    my $type_ret   = pop @types;
    my $arg_count  = @types;
    my $orig       = Sq::Reflection::get_func($func_name);
    my $input_type = t_tuple(@types);
    Sq::Reflection::set_func($func_name, sub {
        local $Carp::CarpLevel = 1;
        # check input arguments by just consider the arguments as a tuple
        t_assert($input_type, \@_);
        # execute original function
        my $ret = $orig->(@_);
        # check return argument
        t_assert($type_ret, $ret);
        return $ret;
    });
    return;
}

# Tuple based function checking. Consider every function as just a function
# with a single input and output. The whole input is passed as an array and
# checked against $in_type. Output again is checked against $out_type.
# So it usually makes sense to use t_tuple for $in_type.
sub sigt($func_name, $in_type, $out_type) {
    my $orig = Sq::Reflection::get_func($func_name);
    Sq::Reflection::set_func($func_name, sub {
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