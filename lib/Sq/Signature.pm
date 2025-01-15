package Sq::Signature;
use 5.036;
use Sq;
use Sq::Reflection qw(get_func set_func set_static is_static);
use Sq::Type qw(t_tuple);
use Sq::Exporter;
our @EXPORT = qw(sig sigt);

# TODO:
# + back-reference an unknown type
# + wrap lambdas with a type-check version
# + functions with list context?
# + easier way for default args

# A Hash that stores which function was already added with a signature.
# Currently just for a check that a function is not set multiple times.
# Later will likely be used to also unload signature at runtime.
my %sigs;

# returns an array of functions added with a signature
sub sigs_added() {
    return bless([keys %sigs], 'Array');
}

sub with_type($in, $out, $name, $f) {
    return sub {
        # check input arguments by just consider the arguments as a tuple
        my $err = $in->(\@_);
        if ( defined $err ) {
            Carp::croak "$name: $err";
        }
        # execute original function
        my $ret = $f->(@_);
        # check return argument
        $err = $out->($ret);
        if ( defined $err ) {
            Carp::croak "$name: Return: $err";
        }
        return $ret;
    }
}

sub sig($func_name, @types) {
    Carp::croak "sig needs at least one type" if @types == 0;
    my $out_type = pop @types;
    my $in_type  = t_tuple(@types);
    sigt($func_name, $in_type, $out_type);
    return;
}

# Tuple based function checking. Consider every function as just a function
# with a single input and output. Theoretically we can say that is already
# the case. In Perl all arguments are put into a single Array -> @_
#
# This input Array is just type-checked with the Sq::Type also the output
# is checked. Because functions are often fixed-size that is the reason
# t_tuple() is used. t_array() for completely variable args or
# t_tuplev() for fixed-size + varargs.
sub sigt($func_name, $in_type, $out_type) {
    if ( $sigs{$func_name} ) { Carp::croak "$func_name: Signature already added" }
    else                     { $sigs{$func_name} = 1                             }

    # When we have a static, then we extract the inner function. And add the
    # type-checking to the inner function. Then a new static with the wrapped
    # type-checking is installed. This has effect on the signature. When a signature
    # for a static is defined then you must define the type-checks for the actual
    # arguments. The empty/leading argument (typical package name) is not visible
    # for the signature anymore.
    if ( is_static $func_name ) {
        my $static = get_func($func_name);
        my $inner  = $static->();
        set_static($func_name, with_type($in_type, $out_type, $func_name, $inner));
    }
    else {
        set_func($func_name, with_type($in_type, $out_type, $func_name, get_func($func_name)));
    }
    return;
}

1;