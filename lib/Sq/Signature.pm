package Sq::Signature;
use 5.036;
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

# with_types() supports multiple IN => OUT definitions. The problem of with_type()
# is that it only supports a single IN and OUT. Usually i use t_or() to provide
# multiple inputs that are possible. But different inputs can have different
# outputs, and they should match. with_type() is not able to support this.
# So a better alternative is created.
sub with_type($name, $f, @in_out) {
    Carp::croak "with_types: \@in_out must be multiple of 2" if @in_out % 2 == 1;
    return sub {
        my @errs;
        for my ($in, $out) ( @in_out) {
            # check if input matches current IN type. When not, try next
            my $err = $in->(\@_);
            if ( $err ) {
                push @errs, $err;
                next;
            }

            # when input matched IN type
            my $ret = $f->(@_);

            # check if return matches OUT type
            $err = $out->($ret);
            if ( defined $err ) {
                Carp::croak("$name: return: $err");
            }

            # return $ret as everything was ok
            return $ret;
        }
        # When we are here, then this means no IN type ever matched.
        # We just print out every failing IN type as an error message
        Carp::croak("$name: \n    ", join("\n    ", @errs));
    }
}

sub sig($func_name, @types) {
    Carp::croak("sig needs at least one type") if @types == 0;
    my $out_type = pop @types;
    local $Carp::CarpLevel += 1;
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
sub sigt($func_name, @in_out) {
    Carp::croak('sige($name, @args): @args must be multiple of 2') if @in_out % 2 == 1;
    if ( $sigs{$func_name} ) { Carp::croak "$func_name: Signature already added" }
    else                     { $sigs{$func_name} = 1                             }

    # When we have a static, then we extract the inner function. And add the
    # type-checking to the inner function. Then a new static with the wrapped
    # type-checking is installed. This has effect on the signature. When a signature
    # for a static is defined then you must define the type-checks for the actual
    # arguments. The empty/leading argument (typical package name) is not visible
    # for the signature anymore.
    for my ($in_type, $out_type) ( @in_out) {
        if ( is_static $func_name ) {
            my $static = get_func($func_name);
            my $inner  = $static->();
            set_static($func_name, with_type($func_name, $inner, @in_out));
        }
        else {
            set_func($func_name, with_type($func_name, get_func($func_name), @in_out));
        }
    }
    return;
}

1;