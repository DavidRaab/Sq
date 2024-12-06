package Sq::Type;
use 5.036;
use Sq;
use Sub::Exporter -setup => {
    exports => [
        qw(t_run t_is t_str t_str_eq), # Basic
        qw(t_opt),
        qw(t_hash t_with_keys t_key),    # Hash
        qw(t_array t_idx),               # Array
        qw(t_all t_length),
    ],
    groups => {
        default => [
            qw(t_run t_is t_str t_str_eq), # Basic
            qw(t_opt),
            qw(t_hash t_with_keys t_key),    # Hash
            qw(t_array t_idx),               # Array
            qw(t_all t_length),
        ],
    },
};

sub t_ref($type, $f) {
    return sub($any) {
        return $f->($any) if ref $any eq $type;
        return Err("Not a reference of type $type");
    }
}

sub t_run($any, @checks) {
    for my $check ( @checks ) {
        my $result = $check->($any);
        return $result if $result->is_err;
    }
    return Ok 1;
}

# check references
sub t_hash(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Hash' || $type eq 'HASH' ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                return $result if $result->is_err;
            }
            return Ok 1;
        }
        return Err("Not a Hash");
    }
}

sub t_array(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                return $result if $result->is_err;
            }
            return Ok 1;
        }
        return Err("Not an Array");
    }
}

sub t_opt(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Option' ) {
            # when $any is some value all @checks must be Ok
            if ( @$any ) {
                for my $check ( @checks ) {
                    my $result = $check->($any->[0]);
                    return $result if $result->is_err;
                }
            }
            # when None or no checks
            return Ok 1;
        }
        return Err("Not an Option");
    }
}

# check hash keys
sub t_with_keys (@keys) {
    return sub($hash) {
        for my $key ( @keys ) {
            return Err("key $key not defined") if !defined $hash->{$key};
        }
        return Ok 1;
    }
}

sub t_key($name, @checks) {
    t_hash(sub($hash) {
        if ( exists $hash->{$name} ) {
            return t_run($hash->{$name}, @checks);
        }
        return Err("$name does not exists on hash");
    });
}

sub t_str_eq($expected) {
    return sub($got) {
        if ( ref $got eq "" ) {
            return Ok(1) if $got eq $expected;
        }
        return Err("Expected: '$expected' got '$got'");
    }
}

sub t_str() {
    return sub($any) {
        return Ok 1 if ref $any eq '';
        return Err("not a string");
    }
}

sub t_idx($index, @checks) {
    t_array(sub($array) {
        t_run($array->[$index], @checks);
    });
}

sub t_is($predicate) {
    return sub($any) {
        if ( $predicate->($any) ) {
            return Ok 1;
        }
        return Err("predicate does not match");
    }
}

sub t_all($is_type) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            for my $x ( @$any ) {
                my $result = $is_type->($x);
                if ( $result->is_err ) {
                    return Err("Element of Array does not match predicate");
                }
            }
            return Ok 1;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            for my $key ( keys %$any ) {
                my $result = $is_type->($any->{$key});
                if ( $result->is_err ) {
                    return Err("A value of a Hash does not match predicate");
                }
            }
            return Ok 1;
        }
        else {
            return Err("$type not supported by t_all");
        }
    }
}

# checks if Array/Hash has minimum upto maximum amount of elements
sub t_length($min, $max=undef) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my $count = @$any;
            return Err("Not enough elements") if $count < $min;
            return Err("Too many elements")   if defined $max && $count > $max;
            return Ok 1;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $count = keys %$any;
            return Err("Not enough elements") if $count < $min;
            return Err("Too many elements")   if defined $max && $count > $max;
            return Ok 1;
        }
        else {
            return Err("Not array-ref nor hash-ref");
        }
    }
}

1;
