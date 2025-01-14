package Sq::Reflection;
use 5.036;
use Sq::Exporter;
our @EXPORT = qw(get_func set_func funcs_of has_func signatures statics);

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
sub static($name, $func) {
    my $full = caller . '::' . $name;
    $statics{$full} = 1;
    Sq::Reflection::set_func($full, sub {
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

sub statics() {
    return bless([keys %statics], 'Array');
}

1;