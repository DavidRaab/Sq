package Sq::Reflection;
use 5.036;
use Sq::Exporter;
our @EXPORT = qw(get_func set_func funcs_of has_func signatures set_static is_static statics);

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
    sub funcs_of($package) {
        my @funcs;
        # Traverse symbol-table
        for my ($key,$glob) ( %{*{$package . '::'}} ) {
            if ( defined *{$glob}{CODE} ) {
                push @funcs, $key;
            }
        }

        return bless(\@funcs, 'Array');
    }

    sub has_func($pkg, $name) {
        return 1 if defined *{"$pkg\::$name"}{CODE};
        return 0;
    }
}

sub signatures() {
    return Sq::Signature::sigs_added();
}

# Keeps information of static functions
my %statics;
sub set_static($full, $func) {
    $statics{$full} = 1;
    set_func($full, sub {
        if ( @_ <= 1 ) {
            return $func;
        }
        else {
            shift @_;
            return $func->(@_);
        }
    });
    return;
}

sub static($name, $func) {
    my $full = caller . '::' . $name;
    set_static($full, $func);
    return;
}

sub is_static($func) {
    return $statics{$func} ? 1 : 0;
}

sub statics() {
    return bless([keys %statics], 'Array');
}

1;