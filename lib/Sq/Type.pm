package Sq::Type;
use 5.036;
use Carp ();
use Scalar::Util ();
use Sq;
use Sq::Parser qw(p_valid);
use Sub::Exporter -setup => {
    exports => [
        qw(t_run t_valid t_assert t_or t_is),            # Basic
        qw(t_str t_enum t_match t_matchf t_parser),      # String
        qw(t_num t_int t_positive t_negative t_range),   # Numbers
        qw(t_opt),
        qw(t_hash t_with_keys t_keys),                   # Hash
        qw(t_array t_idx t_tuple t_tuplev t_even_sized), # Array
        qw(t_of t_min t_max t_length),
        qw(t_any t_sub t_regex t_bool t_seq t_void t_result),
        qw(t_ref t_isa t_can),                           # Objects
    ],
    groups => {
        default => [
            qw(t_run t_valid t_assert t_or t_is),            # Basic
            qw(t_str t_enum t_match t_matchf t_parser),      # String
            qw(t_num t_int t_positive t_negative t_range),   # Numbers
            qw(t_opt),
            qw(t_hash t_with_keys t_keys),                   # Hash
            qw(t_array t_idx t_tuple t_tuplev t_even_sized), # Array
            qw(t_of t_min t_max t_length),
            qw(t_any t_sub t_regex t_bool t_seq t_void t_result),
            qw(t_ref t_isa t_can),                           # Objects
        ],
    },
};

# TODO
# Add: t_not
# Add: t_none, t_any
# Add: t_tuplen
# Add: t_repeat(t_int, t_str, t_int)
#      would be a function that expects the types one or many times in a single array
#      [1,"foo",2,   1,"foo",2,   1,"foo",2, ...]


# The basics of the Result-type that are used in Signature checking are copied here.
# Because the type-checking itself use Result, but Result itself also should be
# enhanced with type-checking it can run into a deep-recursion problem.
# Also i don't need type-checking for the basic data-structure here.
my $valid = [1];
sub valid()         { return $valid                 }
sub invalid($str)   { return [0,$str]               }
sub is_err($result) { return 1 if $result->[0] == 0 }
sub is_ok($result)  { return 1 if $result->[0] == 1 }
sub get($result)    { return $result->[1]           }


### Runners

# t_run: $type -> @values -> Result
sub t_run($check, @values) {
    state $ok = Ok(1);
    Carp::croak "t_run needs a value to check against" if @values == 0;
    for my $value ( @values ) {
        my $result = $check->($value);
        return Err(get $result) if is_err $result;
    }
    return $ok;
}

# t_valid: $type -> @values -> bool
sub t_valid($check, @values) {
    Carp::croak "t_valid needs a value to check against" if @values == 0;
    for my $value ( @values ) {
        my $result = $check->($value);
        return 0 if is_err $result;
    }
    return 1;
}

# t_assert: $type -> @values -> void | EXCEPTION
sub t_assert($check, @values) {
    Carp::croak "t_assert needs a value to check against" if @values == 0;
    for my $value ( @values ) {
        my $result = $check->($value);
        if ( is_err $result ) {
            Carp::croak "Type Error: " . get($result);
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
                if ( is_err $result ) {
                    return invalid("ref: " . get($result));
                }
            }
            return $valid;
        }
        return invalid("ref: Expected '$ref' Got '$type'") if defined $type;
        return invalid("ref: Expected reference, got not reference.");
    }
}

# check references
sub t_hash(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Hash' || $type eq 'HASH' ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                return invalid("hash: " . get($result)) if is_err $result;
            }
            return $valid;
        }
        return invalid("hash: Not a Hash");
    }
}

sub t_array(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                if ( is_err $result ) {
                    return invalid("array: " . get($result));
                }
            }
            return $valid;
        }
        return invalid("array: Not an Array");
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
                    return $result if is_err $result;
                }
            }
            # when None or no checks
            return $valid;
        }
        return invalid("opt: Not an Option");
    }
}

# check hash keys
sub t_with_keys(@keys) {
    return sub($hash) {
        for my $key ( @keys ) {
            return invalid("with_keys: '$key' not defined") if !defined $hash->{$key};
        }
        return $valid;
    }
}

sub t_keys(%kt) {
    return sub($any) {
        my ($type, $result);
        for my $key ( keys %kt ) {
            my $value = $any->{$key};
            if ( !defined $value ) {
                return invalid("keys: '$key' not defined");
            }
            $type   = $kt{$key};
            $result = $type->($value);
            if ( is_err $result ) {
                return invalid("keys: $key " . get($result));
            }
        }
        return $valid;
    }
}

sub t_enum(@expected) {
    return sub($any) {
        if ( ref $any eq "" ) {
            for my $expected ( @expected ) {
                return $valid if $any eq $expected;
            }
            return invalid("enum: Not one of the valid choices");
        }
        return invalid("enum: Not a string");
    }
}

sub t_num(@checks) {
    return sub($any) {
        if ( Scalar::Util::looks_like_number($any) ) {
            for my $check ( @checks ) {
                my $result = t_run($check, $any);
                if ( is_err $result ) {
                    return invalid("num: " . get($result));
                }
            }
            return $valid;
        }
        return invalid("num: Not a number '$any'");
    }
}

sub t_int(@checks) {
    return sub($any) {
        if ( $any =~ m/\A[-+]?\d+\z/ ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                return $result if is_err $result;
            }
            return $valid;
        }
        return invalid("int: Not an integer");
    }
}

sub t_positive() {
    state $fn = sub($any) {
        my $type = ref $any;
        if ( $type eq "" && Scalar::Util::looks_like_number($any) ) {
            return $valid if $any >= 0;
            return invalid("positive: '$any' not >= 0");
        }
        return invalid("positive: Not a number");
    };
    return $fn;
}

sub t_negative() {
    state $fn = sub($any) {
        my $type = ref $any;
        if ( $type eq "" && Scalar::Util::looks_like_number($any) ) {
            return $valid if $any <= 0;
            return invalid("negative: '$any' not <= 0");
        }
        return invalid("negative: Not a number");
    };
    return $fn;
}

sub t_str(@checks) {
    return sub($any) {
        if ( ref $any eq '' ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                if ( is_err $result ) {
                    return invalid("str: " . get($result));
                }
            }
            return $valid;
        }
        return invalid("str: Not a string");
    }
}

sub t_idx($index, @checks) {
    return sub($array) {
        for my $check ( @checks ) {
            my $result = $check->($array->[$index]);
            if ( is_err $result ) {
                return invalid("idx: $index " . get($result));
            }
        }
        return $valid;
    };
}

sub t_is($predicate) {
    return sub($any) {
        return $valid if $predicate->($any);
        return invalid("is: \$predicate not succesful");
    }
}

sub t_of($is_type) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my $idx = 0;
            for my $x ( @$any ) {
                my $result = $is_type->($x);
                if ( is_err $result ) {
                    return invalid("of: index $idx: " . get($result));
                }
                $idx++;
            }
            return $valid;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            for my $key ( keys %$any ) {
                my $result = $is_type->($any->{$key});
                if ( is_err $result ) {
                    return invalid("of: key $key: " . get($result));
                }
            }
            return $valid;
        }
        else {
            return invalid("of: $type not supported by t_of");
        }
    }
}

# checks if Array/Hash/string has minimum upto maximum amount of elements
sub t_length($min, $max) {
    return sub($any) {
        my $type = ref $any;

        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my $length = @$any;
            return invalid("length: Not enough elements") if $length < $min;
            return invalid("length: Too many elements")   if $length > $max;
            return $valid;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $length = keys %$any;
            return invalid("length: Not enough elements") if $length < $min;
            return invalid("length: Too many elements")   if $length > $max;
            return $valid;
        }
        # String
        elsif ( $type eq '' ) {
            my $length = length $any;
            return invalid("lenght: string to short") if $length < $min;
            return invalid("length: string to long")  if $length > $max;
            return $valid;
        }
        else {
            return invalid("length: Not array-ref, hash-ref or string");
        }
    }
}

sub t_match($regex) {
    return sub($any) {
        return $valid if $any =~ $regex;
        return invalid("match: $regex no match: $any");
    }
}

sub t_matchf($regex, $predicate) {
    return sub($str) {
        if ( $str =~ $regex ) {
            return $valid if $predicate->(@{^CAPTURE});
            return invalid("\$predicate not succesful");
        }
        return invalid("matchf: $regex does not match");
    }
}

sub t_min($min) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq "" ) {
            if ( Scalar::Util::looks_like_number($any) ) {
                return $valid if $any >= $min;
                return invalid("min: $any > $min");
            }
            else {
                return $valid if length($any) >= $min;
                return invalid("min: string '$any' shorter than $min");
            }
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            return $valid if @$any >= $min;
            return invalid("min: Array count smaller than $min");
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $length = keys %$any;
            return $valid if $length >= $min;
            return invalid("min: Hash count smaller than $min");
        }
        return invalid("min: Type '$type' not supported");
    }
}

sub t_max($max) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq "" ) {
            if ( Scalar::Util::looks_like_number($any) ) {
                return $valid if $any <= $max;
                return invalid("max: $any > $max");
            }
            else {
                return $valid if length($any) <= $max;
                return invalid("max: string '$any' greater than $max");
            }
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            return $valid if @$any <= $max;
            return invalid("max: Array count greater than $max");
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $length = keys %$any;
            return $valid if $length <= $max;
            return invalid("max: Hash count greater than $max");
        }
        return invalid("max: Type '$type' not supported");
    }
}

sub t_range($min, $max) {
    return sub($num) {
        return $valid if $num >= $min && $num <= $max;
        return invalid("range: $num not between ($min,$max)");
    }
}

sub t_or(@checks) {
    return sub($any) {
        for my $check ( @checks ) {
            my $result = $check->($any);
            return $result if is_ok $result;
        }
        return invalid("or: No check was successfull");
    }
}

# Runs a Parser against a string
sub t_parser($parser) {
    return sub($str) {
        return $valid if p_valid($parser, $str);
        return invalid("parser: string does not match Parser");
    }
}

sub t_any() {
    state $fn = sub($any) { return $valid };
    return $fn;
}

sub t_sub() {
    state $fn = sub($any) {
        return $valid if ref $any eq 'CODE';
        return invalid("sub: Not a CODE reference.");
    };
    return $fn;
}

sub t_regex() {
    state $fn = sub($any) {
        return $valid if ref $any eq 'Regexp';
        return invalid("regex: Not a Regex");
    };
    return $fn;
}

sub t_bool() {
    state $fn = sub($any) {
        if ( Scalar::Util::looks_like_number($any) && ($any == 0 || $any == 1) ) {
            return $valid;
        }
        return invalid("bool: Not a boolean value");
    };
    return $fn;
}

sub t_seq() {
    state $fn = sub($any) {
        return $valid if ref $any eq 'Seq';
        return invalid("seq: Not a sequence");
    };
    return $fn;
}

sub t_void() {
    state $fn = sub($any) {
        # Scalar Context
        return $valid if !defined $any;
        # List context will be checked that the whole list is passed
        # as an array. So someone just can use array checks for list context
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            return $valid if @$any == 0;
        }
        return invalid("void: Not void");
    };
    return $fn;
}

sub t_tuple(@checks) {
    return sub($array) {
        my $type = ref $array;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            if ( @checks == @$array ) {
                my ($type, $value, $result);
                for (my $idx=0; $idx<@checks; $idx++ ) {
                    $type   = $checks[$idx];
                    $value  = $array->[$idx];
                    $result = $type->($value);
                    if ( is_err $result ) {
                        return invalid("tuple: Index $idx: " . get($result));
                    }
                }
                return $valid;
            }
            return invalid(
                sprintf "tuple: Not correct size. Expected: %d Got: %d",
                scalar @checks,
                scalar @$array
            );
        }
        return invalid("tuple: Must be an Array");
    }
}

# variable tuple version. tuplev first expects a minimal fixed amoun of parameters.
# But more than the fixed amount can be passed. All values more than the fixed amount
# are passed as an array to the last type-check passed.
#
# so when someone calls t_tuplev(t_int, t_int, t_array)
#
# then this version has two fixed arguments. And the last check get's all
# remaining variables passed to the last check. Obviously this must be another
# t_array or another t_tuple check again to work.
sub t_tuplev(@checks) {
    my $varargs = pop @checks;
    my $min     = @checks;
    return sub($array) {
        my $type = ref $array;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            # $array must have at least @checks entries
            if ( @$array >= $min ) {
                # first check entries that must be present
                my ($type, $value, $result);
                for (my $idx=0; $idx<@checks; $idx++ ) {
                    $type   = $checks[$idx];
                    $value  = $array->[$idx];
                    $result = $type->($value);
                    if ( is_err $result ) {
                        return invalid("tuplev: Index $idx: " . get($result));
                    }
                }

                # slice the rest of the array and check against $varargs
                my @rest = $array->@[$min .. $#$array];
                if ( @rest > 0 ) {
                    $result = $varargs->(\@rest);
                    if ( is_err $result ) {
                        return invalid("tuplev: varargs failed: " . get($result));
                    }
                }

                # Otherwise everything is ok
                return $valid;
            }
            return invalid(
                sprintf "tuplev: To few elements: Needs at least: %d Got: %d",
                scalar @checks,
                scalar @$array
            );
        }
        return invalid("tuplev: Must be an Array");
    }
}

sub t_even_sized() {
    state $fn = sub($array) {
        my $type = ref $array;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            # binary and to decide if array count is even
            return $valid if ((@$array & 1) == 0);
            return invalid("even_sized: Array not even-sized");
        }
        return invalid("even_sized: Not used on an array");
    };
    return $fn;
}

sub t_can(@methods) {
    return sub($any) {
        my $class = builtin::blessed($any);
        if ( defined $class ) {
            for my $method ( @methods ) {
                my $sub = $any->can($method);
                if ( !defined $sub ) {
                    return invalid("can: $class does not implement '$method'");
                }
            }
            return $valid;
        }
        return invalid("can: not a blessed reference");
    }
}

sub t_isa($class, @checks) {
    return sub($any) {
        if ( $any isa $class ) {
            for my $check ( @checks ) {
                my $result = $check->($any);
                if ( is_err $result ) {
                    return invalid("isa: " . get($result));
                }
            }
            return $valid;
        }
        return invalid("isa: not a blessed reference");
    }
}

sub t_result() {
    state $fn = sub($any) {
        return $valid if ref $any eq 'Result';
        return invalid("result: Not a Result");
    }
}

1;
