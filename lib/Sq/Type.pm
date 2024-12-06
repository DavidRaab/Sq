package Sq::Type;
use 5.036;
use Sq;
use Sub::Exporter -setup => {
    exports => [
        qw(t_check t_hash t_with_key t_key t_array t_idx t_str t_str_eq),
    ],
    groups => {
        default => [
            qw(t_check t_hash t_with_key t_key t_array t_idx t_str t_str_eq),
        ],
    },
};

sub t_ref($type, $f) {
    return sub($any) {
        return $f->($any) if ref $any eq $type;
        return Err("Not a reference of type $type");
    }
}

sub on_hash($f) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Hash' || $type eq 'HASH' ) {
            return $f->($any);
        }
        return Err("Not a Hash");
    }
}

sub on_array($f) {
    return sub($any) {
        my $type = ref $any;
        if ( $type eq 'Array' || $type eq 'ARRAY' ) {
            return $f->($any);
        }
        return Err("Not an Array");
    }
}

sub t_checks($any, $checks) {
    for my $check ( @$checks ) {
        my $result = $check->($any);
        return $result if $result->is_err;
    }
    return Ok 1;
}

sub t_check($obj, $check) {
    t_checks($obj, [$check]);
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

}

# check hash keys
sub t_with_key :prototype($) ($name) {
    return sub($hash) {
        return Ok(1) if defined $hash->{$name};
        return Err("key $name not defined");
    }
}

sub t_key($name, @checks) {
    on_hash(sub($hash) {
        if ( exists $hash->{$name} ) {
            return t_checks($hash->{$name}, \@checks);
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
    return sub($obj) {
        if ( ref $obj eq "" ) {
            return Ok 1;
        }
        return Err("not a string");
    }
}

sub t_idx($index, @checks) {
    on_array(sub($array) {
        t_checks($array->[$index], \@checks);
    });
}

1;
