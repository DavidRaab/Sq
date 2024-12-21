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

# New conept
#
# type-checks return undef for valid, or otherwise an error. Currently
# the error will just be a string. but this reduces the whole checking
# to a defined checking
my $valid = undef;

### Runners

# t_run: $type -> @values -> Result
sub t_run($check, @values) {
    state $ok = Ok(1);
    my $err;
    for my $value ( @values ) {
        $err = $check->($value);
        return Err($err) if defined $err;
    }
    return $ok;
}

# t_valid: $type -> @values -> bool
sub t_valid($check, @values) {
    my $err;
    for my $value ( @values ) {
        $err = $check->($value);
        return 0 if defined $err;
    }
    return 1;
}

# t_assert: $type -> @values -> void | EXCEPTION
sub t_assert($check, @values) {
    my $err;
    for my $value ( @values ) {
        $err = $check->($value);
        Carp::croak "Type Error: $err" if defined $err;
    }
    return;
}

### type checkers

sub t_ref($ref, @checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq $ref ) {
            for my $check ( @checks ) {
                my $err = $check->($any);
                return "ref: $err" if defined $err;
            }
            return $valid;
        }
        return "ref: Expected '$ref' Got '$type'" if defined $type;
        return "ref: Expected reference, got not reference.";
    }
}

# check references
sub t_hash(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($any);
                return "hash: $err" if defined $err;
            }
            return $valid;
        }
        return "hash: Not a Hash";
    }
}

sub t_array(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my $err;
            for my $check ( @checks ) {
                my $err = $check->($any);
                return "array: $err" if defined $err;
            }
            return $valid;
        }
        return "array: Not an Array";
    }
}

sub t_opt(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Option' ) {
            # when $any is some value all @checks must be Ok
            if ( @$any ) {
                my $err;
                for my $check ( @checks ) {
                    my $err = $check->($any->[0]);
                    return "opt: $err" if defined $err;
                }
            }
            # when None or no checks
            return $valid;
        }
        return "opt: Not an Option";
    }
}

# check hash keys
sub t_with_keys(@keys) {
    return sub($hash) {
        my $type = ref $hash;
        if ( $type eq 'Hash' || $type eq 'HASH' ) {
            for my $key ( @keys ) {
                return "with_keys: '$key' not defined" if !defined $hash->{$key};
            }
            return $valid;
        }
        return "with_keys: not a hash";
    }
}

sub t_keys(%kt) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Hash' || $type eq 'HASH' ) {
            my ($err, $value);
            for my $key ( keys %kt ) {
                $value = $any->{$key};
                if ( !defined $value ) {
                    return "keys: '$key' not defined";
                }
                $err = $kt{$key}->($value);
                return "keys: $key $err" if defined $err;
            }
            return $valid;
        }
        return 'keys: not a hash';
    }
}

sub t_enum(@expected) {
    return sub($any) {
        if ( ref $any eq "" ) {
            for my $expected ( @expected ) {
                return $valid if $any eq $expected;
            }
            return "enum: Not one of the valid choices";
        }
        return "enum: Not a string";
    }
}

sub t_num(@checks) {
    return sub($any) {
        if ( Scalar::Util::looks_like_number($any) ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($any);
                return "num: $err" if defined $err;
            }
            return $valid;
        }
        return "num: Not a number '$any'";
    }
}

sub t_int(@checks) {
    return sub($any) {
        if ( $any =~ m/\A[-+]?\d+\z/ ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($any);
                return "int: $err" if defined $err;
            }
            return $valid;
        }
        return "int: Not an integer";
    }
}

sub t_positive() {
    state $fn = sub($any) {
        my $type = ref $any;
        if ( $type eq "" && Scalar::Util::looks_like_number($any) ) {
            return $valid if $any >= 0;
            return "positive: '$any' not >= 0";
        }
        return "positive: Not a number";
    };
    return $fn;
}

sub t_negative() {
    state $fn = sub($any) {
        my $type = ref $any;
        if ( $type eq "" && Scalar::Util::looks_like_number($any) ) {
            return $valid if $any <= 0;
            return "negative: '$any' not <= 0";
        }
        return "negative: Not a number";
    };
    return $fn;
}

sub t_str(@checks) {
    return sub($any) {
        if ( ref $any eq '' ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($any);
                return "str: $err" if defined $err;
            }
            return $valid;
        }
        return "str: Not a string";
    }
}

sub t_idx($index, @checks) {
    return sub($array) {
        my $type = ref $array;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($array->[$index]);
                return "idx: $index $err" if defined $err;
            }
            return $valid;
        }
        return "idx: not an array";
    };
}

sub t_is($predicate) {
    return sub($any) {
        return $valid if $predicate->($any);
        return "is: \$predicate not succesful";
    }
}

sub t_of($is_type) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my ($idx, $err) = (0);
            for my $x ( @$any ) {
                $err = $is_type->($x);
                return "of: index $idx: $err" if defined $err;
                $idx++;
            }
            return $valid;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $err;
            for my $key ( keys %$any ) {
                $err = $is_type->($any->{$key});
                return "of: key $key: $err" if defined $err;
            }
            return $valid;
        }
        else {
            return "of: $type not supported by t_of";
        }
    }
}

# checks if Array/Hash/string has minimum upto maximum amount of elements
sub t_length($min, $max) {
    return sub($any) {
        my $type = ref $any;

        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my $length = @$any;
            return "length: Not enough elements" if $length < $min;
            return "length: Too many elements"   if $length > $max;
            return $valid;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $length = keys %$any;
            return "length: Not enough elements" if $length < $min;
            return "length: Too many elements"   if $length > $max;
            return $valid;
        }
        # String
        elsif ( $type eq '' ) {
            my $length = length $any;
            return "lenght: string to short" if $length < $min;
            return "length: string to long"  if $length > $max;
            return $valid;
        }
        else {
            return "length: Not array-ref, hash-ref or string";
        }
    }
}

sub t_match($regex) {
    return sub($any) {
        return $valid if $any =~ $regex;
        return "match: $regex no match: $any";
    }
}

sub t_matchf($regex, $predicate) {
    return sub($str) {
        if ( $str =~ $regex ) {
            return $valid if $predicate->(@{^CAPTURE});
            return "\$predicate not succesful";
        }
        return "matchf: $regex does not match";
    }
}

sub t_min($min) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq "" ) {
            if ( Scalar::Util::looks_like_number($any) ) {
                return $valid if $any >= $min;
                return "min: $any > $min";
            }
            else {
                return $valid if length($any) >= $min;
                return "min: string '$any' shorter than $min";
            }
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            return $valid if @$any >= $min;
            return "min: Array count smaller than $min";
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $length = keys %$any;
            return $valid if $length >= $min;
            return "min: Hash count smaller than $min";
        }
        return "min: Type '$type' not supported";
    }
}

sub t_max($max) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq "" ) {
            if ( Scalar::Util::looks_like_number($any) ) {
                return $valid if $any <= $max;
                return "max: $any > $max";
            }
            else {
                return $valid if length($any) <= $max;
                return "max: string '$any' greater than $max";
            }
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            return $valid if @$any <= $max;
            return "max: Array count greater than $max";
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my $length = keys %$any;
            return $valid if $length <= $max;
            return "max: Hash count greater than $max";
        }
        return "max: Type '$type' not supported";
    }
}

sub t_range($min, $max) {
    return sub($num) {
        if ( Scalar::Util::looks_like_number($num) ) {
            return $valid if $num >= $min && $num <= $max;
            return "range: $num not between ($min,$max)";
        }
        return "range: not a number";
    }
}

sub t_or(@checks) {
    return sub($any) {
        my $err;
        for my $check ( @checks ) {
            $err = $check->($any);
            return $valid if !defined $err;
        }
        return "or: No check was successfull";
    }
}

# Runs a Parser against a string
sub t_parser($parser) {
    return sub($str) {
        return $valid if p_valid($parser, $str);
        return "parser: string does not match Parser";
    }
}

sub t_any() {
    state $fn = sub($any) { return undef };
    return $fn;
}

sub t_sub() {
    state $fn = sub($any) {
        return $valid if ref $any eq 'CODE';
        return "sub: Not a CODE reference.";
    };
    return $fn;
}

sub t_regex() {
    state $fn = sub($any) {
        return $valid if ref $any eq 'Regexp';
        return "regex: Not a Regex";
    };
    return $fn;
}

sub t_bool() {
    state $fn = sub($any) {
        if ( Scalar::Util::looks_like_number($any) && ($any == 0 || $any == 1) ) {
            return $valid;
        }
        return "bool: Not a boolean value";
    };
    return $fn;
}

sub t_seq() {
    state $fn = sub($any) {
        return $valid if ref $any eq 'Seq';
        return "seq: Not a sequence";
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
        return "void: Not void";
    };
    return $fn;
}

sub t_tuple(@checks) {
    return sub($array) {
        my $type = ref $array;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            if ( @checks == @$array ) {
                my $err;
                for my $idx ( 0 .. $#checks ) {
                    $err = $checks[$idx]->( $array->[$idx] );
                    return "tuple: Index $idx: $err"  if defined $err;
                }
                return $valid;
            }
            return
                sprintf "tuple: Not correct size. Expected: %d Got: %d",
                scalar @checks,
                scalar @$array;
        }
        return "tuple: Must be an Array";
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
                my $err;
                for my $idx ( 0 .. $#checks ) {
                    $err = $checks[$idx]->($array->[$idx]);
                    return "tuplev: Index $idx: $err" if defined $err;
                }

                # slice the rest of the array and check against $varargs
                my @rest = $array->@[$min .. $#$array];
                if ( @rest > 0 ) {
                    $err = $varargs->(\@rest);
                    return "tuplev: varargs failed: $err" if defined $err;
                }

                # Otherwise everything is ok
                return $valid;
            }
            return
                sprintf "tuplev: To few elements: Needs at least: %d Got: %d",
                scalar @checks,
                scalar @$array;
        }
        return "tuplev: Must be an Array";
    }
}

sub t_even_sized() {
    state $fn = sub($array) {
        my $type = ref $array;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            # binary-and to decide if array count is even
            return $valid if ((@$array & 1) == 0);
            return "even_sized: Array not even-sized";
        }
        return "even_sized: Not used on an array";
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
                    return "can: $class does not implement '$method'";
                }
            }
            return $valid;
        }
        return "can: not a blessed reference";
    }
}

sub t_isa($class, @checks) {
    return sub($any) {
        if ( $any isa $class ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($any);
                return "isa: $err" if defined $err;
            }
            return $valid;
        }
        return "isa: not a blessed reference";
    }
}

sub t_result() {
    state $fn = sub($any) {
        return $valid if ref $any eq 'Result';
        return "result: Not a Result";
    }
}

1;
