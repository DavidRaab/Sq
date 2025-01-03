package Sq::Signature;
use 5.036;
use Sq;
use Sq::Type qw(t_tuple);
use Sq::Exporter;
our @EXPORT = qw(sig sigt);

# TODO:
# + back-reference an unknown type
# + wrap lambdas with a type-check version
# + functions with list context?
# + easier way for default args

sub sig($func_name, @types) {
    Carp::croak "sig needs at least one type" if @types == 0;
    my $orig       = Sq::Reflection::get_func($func_name);
    my $out_type   = pop @types;
    my $in_type    = t_tuple(@types);
    my $arg_count  = @types;
    Sq::Reflection::set_func($func_name, sub {
        # check input arguments by just consider the arguments as a tuple
        my $err = $in_type->(\@_);
        if ( defined $err ) {
            Carp::croak "$func_name: $err";
        }
        # execute original function
        my $ret = $orig->(@_);
        # check return argument
        $err = $out_type->($ret);
        if ( defined $err ) {
            Carp::croak "$func_name: Return: $err";
        }
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
        my $err = $in_type->(\@_);
        if ( defined $err ) {
            Carp::croak "$func_name: $err";
        }
        my $ret = $orig->(@_);
        $err = $out_type->($ret);
        if ( defined $err ) {
            Carp::croak "$func_name: Return: $err";
        }
        return $ret;
    });
}

# a function with multiple different signatures
sub sigm($func_name, @multi) {

}

# when a function has variable args
sub sigv { ... }

1;