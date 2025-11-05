package Sq::Copy;
use 5.036;

# This is inlined in copy() but i still provide this function as an API
# called by other code
sub hash($hash, $other) { ... }

# This is inlined in copy() but i still provide this function as an API
# called by other code
sub array($array)   { ... }
sub seq($seq)       { ... }
sub result($result) { ... }
sub du($union)      { ... }
sub du_case($union) { ... }

# As far i see Path::Tiny objects has no mutation methods, so they can be returned as-is.
sub path_tiny($path) {
    return $path;
}

my $dispatch = {
    'Result'             => \&result,
    'Seq'                => \&seq,
    'Sq::Core::DU'       => \&du,
    'Sq::Core::DU::Case' => \&du_case,
    'Path::Tiny'         => \&path_tiny,
};

sub copy($any) {
    my $ref = ref $any;
    if ( $ref eq "" ) {
        return $any;
    }
    elsif( $ref eq 'Array' || $ref eq 'ARRAY' ) {
        my $new = bless([], 'Array');
        for my $x ( @$any ) {
            if ( defined $x ) {
                push @$new, copy($x);
            }
            else {
                return $new;
            }
        }
        return $new;
    }
    elsif ( $ref eq 'Hash' || $ref eq 'HASH' ) {
        my $new = bless({}, 'Hash');
        for my ($k,$v) ( %$any ) {
            $new->{$k} = copy($v);
        }
        return $new;
    }
    elsif ( $ref eq 'Option' ) {
        my $new = bless([], 'Option');
        for my $x ( @$any ) {
            push @$new, copy($x);
        }
        return $new;
    }
    elsif ( $ref eq 'Result' ) {
        return bless([$any->[0], copy($any->[1])], 'Result');
    }
    elsif ( $ref eq 'Seq' ) {
        return $any;
    }
    else {
        my $func = $dispatch->{$ref};
        if ( defined $func ) {
            return $func->($any);
        }
        Carp::croak "No copy for '$ref' defined.";
    }
}

sub add_copy($type, $func) {
    Carp::croak "You must provide a string"        if not Sq::is_str($type);
    Carp::croak "You must provide a copy function" if ref $func ne 'CODE';
    $dispatch->{$type} = $func;
    return;
}

# Add equal function to other packages
no warnings 'once';
*Array::copy  = \&copy;
*Hash::copy   = \&copy;
*Seq::copy    = \&copy;
*Option::copy = \&copy;
*Result::copy = \&copy;

1;