package Sq::Type;
use 5.036;
use Carp ();
use Scalar::Util ();
use Sq;
use Sq::Parser qw(p_valid);
use Sub::Exporter -setup => {
    exports => [
        qw(t_run t_valid t_assert t_or t_is),         # Basic
        qw(t_str t_str_eq t_match t_matchf t_parser), # String
        qw(t_num t_int t_min t_max t_range),          # Numbers
        qw(t_opt),
        qw(t_hash t_has_keys t_key t_keys),           # Hash
        qw(t_array t_idx t_tuple t_even_sized),       # Array
        qw(t_all t_length),
        qw(t_any t_sub t_regex t_bool t_seq t_void),
        qw(t_ref t_isa t_methods),                    # Objects
    ],
    groups => {
        default => [
            qw(t_run t_valid t_assert t_or t_is),         # Basic
            qw(t_str t_str_eq t_match t_matchf t_parser), # String
            qw(t_num t_int t_min t_max t_range),          # Numbers
            qw(t_opt),
            qw(t_hash t_has_keys t_key t_keys),           # Hash
            qw(t_array t_idx t_tuple t_even_sized),       # Array
            qw(t_all t_length),
            qw(t_any t_sub t_regex t_bool t_seq t_void),
            qw(t_ref t_isa t_methods),                    # Objects
        ],
    },
};

# TODO
# Add: t_not
# Add: t_none, t_any

### Runners

# t_run: $type -> @values -> Result
sub t_run($check, @values) {
    Carp::croak "t_run needs a value to check against" if @values == 0;
    for my $value ( @values ) {
        my $result = $check->($value);
        return $result if $result->is_err;
    }
    return Ok 1;
}

# t_valid: $type -> @values -> bool
sub t_valid($check, @values) {
    Carp::croak "t_valid needs a value to check against" if @values == 0;
    for my $value ( @values ) {
        my $result = $check->($value);
        return 0 if $result->is_err;
    }
    return 1;
}

# t_assert: $type -> @values -> void | EXCEPTION
sub t_assert($check, @values) {
    Carp::croak "t_assert needs a value to check against" if @values == 0;
    for my $value ( @values ) {
        my $result = $check->($value);
        if ( $result->is_err ) {
            my $err = $result->get;
            Carp::croak "Type Error: $err";
        }
    }
    return;
}

### type checkers

sub t_ref($ref, @checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq $ref ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                if ( $result->is_err ) {
                    my $msg = $result->get;
                    return Err("ref: $msg");
                }
            }
            return Ok 1;
        }
        return Err("ref: Expected '$ref' Got '$type'") if defined $type;
        return Err("ref: Expected reference, got not reference.");
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
        return Err("hash: Not a Hash");
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
        return Err("array: Not an Array");
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
        return Err("opt: Not an Option");
    }
}

# check hash keys
sub t_has_keys(@keys) {
    return sub($hash) {
        for my $key ( @keys ) {
            return Err("has_keys: key \"$key\" not defined") if !defined $hash->{$key};
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
        return Err("key: $name does not exists on hash");
    };
}

sub t_keys(%kt) {
    return sub($any) {
        for my $key ( keys %kt ) {
            my $type   = $kt{$key};
            my $result = t_run(t_key($key, $type), $any);
            return $result if $result->is_err;
            return Err("keys: $key failed type") if $result->is_err;
        }
        return Ok 1;
    }
}

sub t_str_eq($expected) {
    return sub($any) {
        if ( ref $any eq "" ) {
            return Ok(1) if $any eq $expected;
        }
        return Err("str_eq: Expected: '$expected' got '$any'");
    }
}

sub t_num(@checks) {
    return sub($any) {
        if ( Scalar::Util::looks_like_number($any) ) {
            for my $check ( @checks ) {
                my $result = t_run($check, $any);
                if ( $result->is_err ) {
                    my $msg = $result->get;
                    return Err("num: $msg");
                }
            }
            return Ok 1;
        }
        return Err("num: Not a number");
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
        return Err("int: Not an integer");
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
        return Err("str: Not a string");
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
        return Err("is: \$predicate not succesful");
    }
}

sub t_all($is_type) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            for my $x ( @$any ) {
                my $result = $is_type->($x);
                if ( $result->is_err ) {
                    return Err("all: Element of Array does not match predicate");
                }
            }
            return Ok 1;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            for my $key ( keys %$any ) {
                my $result = $is_type->($any->{$key});
                if ( $result->is_err ) {
                    return Err("all: A value of a Hash does not match predicate");
                }
            }
            return Ok 1;
        }
        else {
            return Err("all: $type not supported by t_all");
        }
    }
}

# checks if Array/Hash/string has minimum upto maximum amount of elements
sub t_length($min, $max=undef) {
    return sub($any) {
        my $type = ref $any;

        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my $length = @$any;
            return Err("length: Not enough elements") if $length < $min;
            return Err("length: Too many elements")   if defined $max && $length > $max;
            return Ok 1;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $length = keys %$any;
            return Err("length: Not enough elements") if $length < $min;
            return Err("length: Too many elements")   if defined $max && $length > $max;
            return Ok 1;
        }
        # String
        elsif ( $type eq '' ) {
            my $length = length $any;
            return Err("lenght: string to short") if $length < $min;
            return Err("length: string to long")  if defined $max && $length > $max;
            return Ok 1;
        }
        else {
            return Err("length: Not array-ref, hash-ref or string");
        }
    }
}

sub t_match($regex) {
    return sub($any) {
        return Ok 1 if $any =~ $regex;
        return Err("match: $regex no match: $any");
    }
}

sub t_matchf($regex, $predicate) {
    return sub($str) {
        if ( $str =~ $regex ) {
            return Ok 1 if $predicate->(@{^CAPTURE});
            return Err("\$predicate not succesful");
        }
        return Err("matchf: $regex does not match");
    }
}

sub t_min($min) {
    return sub($num) {
        return Ok 1 if $num >= $min;
        return Err("min: $num >= $min");
    }
}

sub t_max($max) {
    return sub($num) {
        return Ok 1 if $num <= $max;
        return Err("max: $num <= $max");
    }
}

sub t_range($min, $max) {
    return sub($num) {
        return Ok 1 if $num >= $min && $num <= $max;
        return Err("range: $num not between ($min,$max)");
    }
}

sub t_or(@checks) {
    return sub($any) {
        for my $check ( @checks ) {
            my $result = $check->($any);
            return $result if $result->is_ok;
        }
        return Err("or: No check was successfull");
    }
}

# Runs a Parser against a string
sub t_parser($parser) {
    return sub($str) {
        return Ok 1 if p_valid($parser, $str);
        return Err("parser: string does not match Parser");
    }
}

sub t_any() {
    return sub($any) { return Ok 1 };
}

sub t_sub() {
    return sub($any) {
        return Ok 1 if ref $any eq 'CODE';
        return Err("sub: Not a CODE reference.");
    };
}

sub t_regex() {
    return sub($any) {
        return Ok 1 if ref $any eq 'Regexp';
        return Err("regex: Not a Regex");
    }
}

sub t_bool() {
    return sub($any) {
        if ( Scalar::Util::looks_like_number($any) && ($any == 0 || $any == 1) ) {
            return Ok 1;
        }
        return Err("bool: Not a boolean value");
    }
}

sub t_seq() {
    return sub($any) {
        return Ok 1 if ref $any eq 'Seq';
        return Err("seq: Not a sequence");
    }
}

sub t_void() {
    return sub($any) {
        # Scalar Context
        return Ok 1 if !defined $any;
        # List context will be checked that the whole list is passed
        # as an array. So someone just can use array checks for list context
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            return Ok 1 if @$any == 0;
        }
        return Err("void: Not void");
    }
}

sub t_tuple(@checks) {
    return sub($array) {
        my $type = ref $array;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            if ( @checks == @$array ) {
                for (my $idx=0; $idx<@checks; $idx++ ) {
                    my $type   = $checks[$idx];
                    my $value  = $array->[$idx];
                    my $result = $type->($value);
                    if ( $result->is_err ) {
                        my $msg = $result->get;
                        return Err("tuple: Index $idx: $msg");
                    }
                }
                return Ok 1;
            }
            return Err(
                sprintf "tuple: Not correct size. Expected: %d Got: %d",
                scalar @checks,
                scalar @$array
            );
        }
        return Err("tuple: Must be an Array");
    }
}

sub t_even_sized() {
    return sub($array) {
        my $type = ref $array;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            # binary and to decide if array count is even
            return Ok 1 if ((@$array & 1) == 0);
            return Err("even_sized: Array not even-sized");
        }
        return Err("even_sized: Not used on an array");
    }
}

sub t_methods(@methods) {
    return sub($any) {
        my $class = Scalar::Util::blessed($any);
        if ( defined $class ) {
            for my $method ( @methods ) {
                my $sub = $any->can($method);
                if ( !defined $sub ) {
                    return Err("methods: $class does not implement '$method'");
                }
            }
            return Ok 1;
        }
        return Err("methods: not a blessed reference");
    }
}

sub t_isa($class, @checks) {
    return sub($any) {
        if ( $any isa $class ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                if ( $result->is_err ) {
                    my $msg = $result->get;
                    return Err("isa: $msg");
                }
            }
            return Ok 1;
        }
        return Err("isa: not a blessed reference");
    }
}

1;
