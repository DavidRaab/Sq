package Sq::Type;
use 5.036;
use Carp ();
use Scalar::Util ();
use Sq;
use Sub::Exporter -setup => {
    exports => [
        qw(t_run t_valid t_assert t_or t_is), # Basic
        qw(t_str t_str_eq t_match),           # String
        qw(t_num t_int t_min t_max t_range),  # Numbers
        qw(t_opt),
        qw(t_hash t_has_keys t_key t_keys),   # Hash
        qw(t_array t_idx),                    # Array
        qw(t_all t_length),
    ],
    groups => {
        default => [
            qw(t_run t_valid t_assert t_or t_is), # Basic
            qw(t_str t_str_eq t_match),           # String
            qw(t_num t_int t_min t_max t_range),  # Numbers
            qw(t_opt),
            qw(t_hash t_has_keys t_key t_keys),   # Hash
            qw(t_array t_idx),                    # Array
            qw(t_all t_length),
        ],
    },
};

# TODO
# Add: t_and, t_not
# Add: t_int
# Add: t_none, t_any
# Add: t_parser

### Runners

# t_run: $type -> @values -> Result
sub t_run($check, @values) {
    for my $value ( @values ) {
        my $result = $check->($value);
        return $result if $result->is_err;
    }
    return Ok 1;
}

# t_valid: $type -> @values -> bool
sub t_valid($check, @values) {
    for my $value ( @values ) {
        my $result = $check->($value);
        return 0 if $result->is_err;
    }
    return 1;
}

# t_assert: $type -> @values -> void | EXCEPTION
sub t_assert($check, @values) {
    for my $value ( @values ) {
        my $result = $check->($value);
        Carp::croak 'Type check failed' if $result->is_err;
    }
    return;
}

### type checkers

sub t_ref($ref, $f) {
    return sub($any) {
        return $f->($any) if ref $any eq $ref;
        return Err("Not a reference of type $ref");
    }
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
sub t_has_keys (@keys) {
    return sub($hash) {
        for my $key ( @keys ) {
            return Err("key $key not defined") if !defined $hash->{$key};
        }
        return Ok 1;
    }
}

sub t_key($name, @checks) {
    return sub($hash) {
        my $value = $hash->{$name};
        if ( defined $value ) {
            for my $check ( @checks ) {
                my $result = $check->($value);
                return $result if $result->is_err;
            }
            return Ok 1;
        }
        return Err("$name does not exists on hash");
    };
}

sub t_keys(%kt) {
    return sub($any) {
        for my $key ( keys %kt ) {
            my $type   = $kt{$key};
            my $result = t_run(t_key($key, $type), $any);
            return $result if $result->is_err;
        }
        return Ok 1;
    }
}

sub t_str_eq($expected) {
    return sub($any) {
        if ( ref $any eq "" ) {
            return Ok(1) if $any eq $expected;
        }
        return Err("Expected: '$expected' got '$any'");
    }
}

sub t_num(@checks) {
    return sub($any) {
        if ( Scalar::Util::looks_like_number($any) ) {
            for my $check ( @checks ) {
                my $result = t_run($check, $any);
                return $result if $result->is_err;
            }
            return Ok 1;
        }
        return Err("Not a number");
    }
}

sub t_int(@checks) {
    return sub($any) {
        if ( $any =~ m/\A[-+]?\d+\z/ ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                return $result if $result->is_err;
            }
            return Ok 1;
        }
        return Err("Not an integer");
    }
}

sub t_str(@checks) {
    return sub($any) {
        if ( ref $any eq '' ) {
            for my $check ( @checks ) {
                my $result = t_run($check, $any);
                return $result if $result->is_err;
            }
            return Ok 1;
        }
        return Err("not a string");
    }
}

sub t_idx($index, @checks) {
    return sub($array) {
        for my $check ( @checks ) {
            my $result = $check->($array->[$index]);
            return $result if $result->is_err;
        }
        return Ok 1;
    };
}

sub t_is($predicate) {
    return sub($any) {
        return Ok 1 if $predicate->($any);
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
            my $length = @$any;
            return Err("Not enough elements") if $length < $min;
            return Err("Too many elements")   if defined $max && $length > $max;
            return Ok 1;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $length = keys %$any;
            return Err("Not enough elements") if $length < $min;
            return Err("Too many elements")   if defined $max && $length > $max;
            return Ok 1;
        }
        # String
        elsif ( $type eq '' ) {
            my $length = length $any;
            return Err("string to short") if $length < $min;
            return Err("string to long")  if defined $max && $length > $max;
            return Ok 1;
        }
        else {
            return Err("Not array-ref, hash-ref or string");
        }
    }
}

sub t_match($regex) {
    return sub($any) {
        return Ok 1 if $any =~ $regex;
        return Err("$regex no match: $any");
    }
}

sub t_min($min) {
    return sub($num) {
        return Ok 1 if $num >= $min;
        return Err("$num must be greater $min");
    }
}

sub t_max($max) {
    return sub($num) {
        return Ok 1 if $num <= $max;
        return Err("$num must be smaller $max");
    }
}

sub t_range($min, $max) {
    return sub($num) {
        return Ok 1 if $num >= $min && $num <= $max;
        return Err("$num must be between $min - $max");
    }
}

sub t_or(@checks) {
    return sub($any) {
        for my $check ( @checks ) {
            my $result = $check->($any);
            return $result if $result->is_ok;
        }
        return Err("No check was successfull");
    }
}

1;
