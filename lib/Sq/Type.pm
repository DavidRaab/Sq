package Sq::Type;
use 5.036;
use Sq::Evaluator;
use Sq::Exporter;
our @EXPORT = (
    qw(type),
    qw(t_run t_valid t_assert),                                 # Runners
    qw(t_and t_or t_is t_not t_rec t_maybe),                    # Combinators
    qw(t_str t_enum t_match t_matchf t_parser t_eq),            # String
    qw(t_num t_int t_positive t_negative t_range),              # Numbers
    qw(t_hash t_with_keys t_keys t_as_hash t_key_is),           # Hash
    qw(t_array t_idx t_tuple t_tuplev t_even_sized),            # Array
    qw(t_any t_opt t_sub t_regex t_bool t_seq t_void t_result), # Basic Types
    qw(t_of t_min t_max t_length),
    qw(t_ref t_isa t_can),                                      # Objects
    qw(t_union t_runion),
);

# Manual import
*blessed = \&builtin::blessed;
*is_num  = \&Scalar::Util::looks_like_number;
*Ok      = \&Result::Ok;
*Err     = \&Result::Err;

# TODO
# Add: t_none
# Add: t_tuplen

# type-checks return undef for valid, or otherwise an error. Currently
# the error will just be a string. but this reduces the whole checking
# to a defined checking.
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
        Carp::croak "Type Error: $err\n" if defined $err;
    }
    return;
}

### Combinators

sub t_or(@checks) {
    return sub($any) {
        my @errs;
        for my $check ( @checks ) {
            my $err = $check->($any);
            return $valid if !defined $err;
            push @errs, $err;
        }
        return "or: No check succesfull"
            . "\n    "
            . join("\n    ", @errs);
    }
}

sub t_and(@checks) {
    return sub($any) {
        my $err;
        for my $check ( @checks ) {
            $err = $check->($any);
            return "and: " . $err if defined $err;
        }
        return $valid;
    }
}

sub t_is($predicate) {
    return sub($any) {
        return $valid if $predicate->($any);
        return "is: \$predicate not succesful";
    }
}

sub t_not(@checks) {
    return sub($any) {
        my $err;
        for my $check ( @checks ) {
            $err = $check->($any);
            return "not: check valid" if !defined $err;
        }
        return $valid;
    }
}

### type checkers

sub t_ref($ref, @checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq $ref ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($any);
                return "ref: $err" if defined $err;
            }
            return $valid;
        }
        return "ref: Expected '$ref' Got '$type'" if $type ne "";
        return "ref: Expected ref. Got: '$any'";
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
                $err = $check->($any);
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
                    $err = $check->($any->[0]);
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
            for my ($key,$check) ( %kt ) {
                $value = $any->{$key};
                $err   = $check->($value);
                return "keys: $key $err" if defined $err;
            }
            return $valid;
        }
        return 'keys: not a hash';
    }
}

sub t_maybe($check) {
    return sub($any) {
        if ( defined $any ) {
            my $err = $check->($any);
            return "maybe: " . $err if defined $err;
        }
        return $valid;
    }
}

sub t_eq($expect) {
    return sub($any) {
        return "eq: Got undef" if !defined $any;
        if ( ref $any eq "" ) {
            return $valid if $any eq $expect;
            return "eq: Expected '$expect' Got '$any'";
        }
        return "eq: Not a string";
    }
}

sub t_enum(@expected) {
    return sub($any) {
        return "enum: Got undef" if !defined $any;
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
        return "num: Got undef" if !defined $any;
        if ( is_num($any) ) {
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
        return "int: Got undef" if !defined $any;
        if ( $any =~ m/\A[-+]?[0-9]+\z/ ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($any);
                return "int: $err" if defined $err;
            }
            return $valid;
        }
        return "int: Not int";
    }
}

sub t_positive() {
    state $fn = sub($any) {
        return "positive: Got undef" if !defined $any;
        if ( is_num($any) ) {
            return $valid if $any >= 0;
            return "positive: '$any' not >= 0";
        }
        return "positive: Not a number";
    };
    return $fn;
}

sub t_negative() {
    state $fn = sub($any) {
        return "negative: Got undef" if !defined $any;
        if ( is_num($any) ) {
            return $valid if $any <= 0;
            return "negative: '$any' not <= 0";
        }
        return "negative: Not a number";
    };
    return $fn;
}

sub t_str(@checks) {
    return sub($any) {
        return "str: Got undef" if !defined $any;
        my $type = ref $any;
        if ( $type eq '' ) {
            my $err;
            for my $check ( @checks ) {
                $err = $check->($any);
                return "str: $err" if defined $err;
            }
            return $valid;
        }
        return "str: Expected string got '$type'";
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

sub t_of(@types) {
    my $count = @types;
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            if ( @$any % $count > 0 ) {
                return "of: Array not multiple of $count";
            }
            my ($idx, $is_type, $err) = (0);
            for my $x ( @$any ) {
                $is_type = $types[$idx % $count];
                $err     = $is_type->($x);
                return "of: index $idx: $err" if defined $err;
                $idx++;
            }
            return $valid;
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            my ($err);
            KEY:
            for my ($key,$value) ( %$any ) {
                for my $is_type ( @types ) {
                    $err = $is_type->($value);
                    next KEY if !defined $err;
                }
                return "of: No type-check was succesfull";
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
        return "length: Got undef" if !defined $any;
        my $type = ref $any;

        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            my $length = @$any;
            return "length: Expected: $min-$max Got: $length" if $length < $min;
            return "length: Expected: $min-$max Got: $length" if $length > $max;
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
        return "match: Got undef" if !defined $any;
        return $valid if $any =~ $regex;
        return "match: $regex no match: $any";
    }
}

sub t_matchf($regex, $predicate) {
    return sub($any) {
        return "matchf: Got undef" if !defined $any;
        my $ref = ref $any;
        if ( $ref eq '' ) {
            if ( $any =~ $regex ) {
                return $valid if $predicate->(@{^CAPTURE});
                return "\$predicate not succesful";
            }
            else {
                return "matchf: No match: $regex =~ '$any'";
            }
        }
        return "matchf: Not a string";
    }
}

sub t_min($min) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq "" ) {
            if ( is_num($any) ) {
                return $valid if $any >= $min;
                return "min: $min Got: $any";
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
            if ( is_num($any) ) {
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

# range check is inclusive
sub t_range($min, $max) {
    return sub($num) {
        if ( is_num($num) ) {
            return $valid if $num >= $min && $num <= $max;
            return "range: Expected: $min-$max Got: $num";
        }
        return "range: not a number";
    }
}

# Runs a Parser against a string
sub t_parser($parser) {
    require Sq::Parser;
    return sub($str) {
        return $valid if Sq::Parser::p_valid($parser, $str);
        return "parser: string does not match Parser";
    }
}

sub t_any() {
    state $fn = sub($any) { return undef };
    return $fn;
}

sub t_sub() {
    state $fn = sub($any) {
        my $type = ref $any;
        return $valid if $type eq 'CODE' || $type eq 'Sq::Lazy';
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
        if ( is_num($any) && ($any == 0 || $any == 1) ) {
            return $valid;
        }
        return "bool: Not a boolean value";
    };
    return $fn;
}

sub t_seq() {
    state $fn = sub($any) {
        my $ref = ref $any;
        return $valid if $ref eq 'Seq';
        return "seq: Not a sequence: Got $ref";
    };
    return $fn;
}

sub t_void() {
    state $fn = sub($any) {
        # Scalar Context
        return $valid if !defined $any;
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

# variable tuple version. tuplev first expects a minimal fixed amount of parameters.
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
            # $array must have at least $min (@checks-1) entries
            if ( @$array >= $min ) {
                # first check entries that must be present
                my $err;
                for my $idx ( 0 .. $#checks ) {
                    $err = $checks[$idx]->($array->[$idx]);
                    return "tuplev: Index $idx: $err" if defined $err;
                }

                # slice the rest of the array and check against $varargs
                my @rest = $array->@[$min .. $#$array];
                $err = $varargs->(\@rest);
                return "tuplev: varargs failed: $err" if defined $err;

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
        my $class = blessed($any);
        if ( defined $class ) {
            my $sub;
            for my $method ( @methods ) {
                $sub = $any->can($method);
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
        return "isa: Not $class";
    }
}

sub t_result {
    Carp::croak 't_result() or t_result($ok,$err)' if not (@_ == 0 || @_ == 2);
    my ($ok,$err) = @_;
    my $args      = @_;
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Result' ) {
            return $valid if $args == 0;
            # Err
            if ( $any->[0] == 0 ) {
                my $msg = $err->($any->[1]);
                return "result: $msg" if defined $msg;
            }
            # Ok
            else {
                my $msg = $ok->($any->[1]);
                return "result: $msg" if defined $msg;
            }
            return $valid;
        }
        return "result: Not Result. Got: $type";
    }
}

sub t_as_hash(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            return "as_hash: Not even-sized array" if @$any % 2 == 1;
            my $hash = { @$any };
            my $err;
            for my $check ( @checks ) {
                $err = $check->($hash);
                return "as_hash: $err" if defined $err;
            }
            return $valid;
        }
        return "as_hash: Not Array. Got: $type";
    }
}

sub t_key_is(@checks) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Hash' || $type eq 'HASH' ) {
            for my $key ( keys %$any ) {
                my $err;
                for my $check ( @checks ) {
                    $err = $check->($key);
                    return "key_is: $err" if defined $err;
                }
            }
            return $valid;
        }
        return "key_is: Not Hash. Got: $type";
    }
}

sub t_rec($sub) {
    Carp::croak "rec needs a sub-ref" if ref $sub ne 'CODE';
    return sub($any) {
        my $type = $sub->();
        my $err  = $type->($any);
        return "rec: $err" if defined $err;
        return $valid;
    }
}

sub t_union($union) {
    Carp::croak "Need an union-type" if ref $union ne 'Sq::Core::DU';
    return sub($any) {
        return $valid if Sq::Core::DU::is_case($union, $any);
        return "union: Not a case of union";
    }
}

sub t_runion($f_union) {
    Carp::croak "Need an union-type" if ref $f_union ne 'CODE';
    return sub($any) {
        my $union = $f_union->();
        return $valid if Sq::Core::DU::is_case($union, $any);
        return "runion: Not a case of union";
    }
}

sub type :prototype($) {
    state $table = { map { s/\At_//r => \&$_ } grep { m/\At_/ } @EXPORT };
    my ( $array ) = @_;
    return eval_data($table, $array);
}

1;
