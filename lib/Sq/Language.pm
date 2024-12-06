package Sq::Language;
use 5.036;
use Sub::Exporter -setup => {
    exports => [
        qw(check a_hash with_key key a_array idx str is_str),
        qw(ok err is_ok is_err match),
    ],
    groups => {
        default => [
            qw(check a_hash with_key key a_array idx str is_str),
        ],
        error => [
            qw(ok err is_ok is_err match)
        ]
    },
};

# Error Type
sub ok ($value)  { return [Ok  => $value] }
sub err($value)  { return [Err => $value] }
sub is_error($obj) {
    if (
        ref $obj eq 'ARRAY'
        && @$obj == 2
        && ($obj->[0] eq 'Ok') or ($obj->[0] eq 'Err')
    ) {
        return $obj->[0];
    }
    return "";
}
sub value ($obj) { return $obj->[1]                    }
sub is_ok ($obj) { return 1 if is_error($obj) eq 'Ok'  }
sub is_err($obj) { return 1 if is_error($obj) eq 'Err' }

sub match($obj, $ok, $err) {
    return value($obj) if is_error($obj);
    die "\$obj is not an Error-Type\n";
}

# Language
sub on_ref($type, $f) {
    return sub($obj) {
        if ( ref $obj eq $type ) {
            return $f->($obj);
        }
        else {
            return err("Not a $type");
        }
    }
}

sub on_hash($f)  { on_ref('HASH',  $f) }
sub on_array($f) { on_ref('ARRAY', $f) }

sub checks($obj, $checks) {
    for my $check ( @$checks ) {
        my $result = $check->($obj);
        return $result if is_err($result);
    }
    return ok 1;
}

sub check($obj, $check) {
    checks($obj, [$check]);
}


# check references
sub a_hash(@checks) {
    on_hash(sub($hash) {
        checks($hash, \@checks);
    });
}

sub a_array(@checks) {
    on_array(sub($array) {
        checks($array, \@checks);
    });
}

# check hash keys
sub with_key :prototype($) ($name) {
    return sub($hash) {
        return ok(1) if defined $hash->{$name};
        return err("key $name not defined");
    }
}

sub key($name, @checks) {
    on_hash(sub($hash) {
        if ( exists $hash->{$name} ) {
            return checks($hash->{$name}, \@checks);
        }
        return err("$name does not exists on hash");
    });
}


sub str($expected) {
    return sub($got) {
        if ( ref $got eq "" ) {
            return ok(1) if $got eq $expected;
        }
        return err("Expected: '$expected' got '$got'");
    }
}

sub is_str() {
    return sub($obj) {
        if ( ref $obj eq "" ) {
            return ok(1);
        }
        return err("not a string");
    }
}

sub idx($index, @checks) {
    on_array(sub($array) {
        checks($array->[$index], \@checks);
    });
}

1;
