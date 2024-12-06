package Sq::Language;
use 5.036;
use Sq;
use Sub::Exporter -setup => {
    exports => [
        qw(check a_hash with_key key a_array idx str is_str),
    ],
    groups => {
        default => [
            qw(check a_hash with_key key a_array idx str is_str),
        ],
    },
};

# Language
sub on_ref($type, $f) {
    return sub($obj) {
        if ( ref $obj eq $type ) {
            return $f->($obj);
        }
        else {
            return Err("Not a $type");
        }
    }
}

sub on_hash($f)  { on_ref('HASH',  $f) }
sub on_array($f) { on_ref('ARRAY', $f) }

sub checks($obj, $checks) {
    for my $check ( @$checks ) {
        my $result = $check->($obj);
        return $result if $result->is_err;
    }
    return Ok 1;
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
        return Ok(1) if defined $hash->{$name};
        return Err("key $name not defined");
    }
}

sub key($name, @checks) {
    on_hash(sub($hash) {
        if ( exists $hash->{$name} ) {
            return checks($hash->{$name}, \@checks);
        }
        return Err("$name does not exists on hash");
    });
}


sub str($expected) {
    return sub($got) {
        if ( ref $got eq "" ) {
            return Ok(1) if $got eq $expected;
        }
        return Err("Expected: '$expected' got '$got'");
    }
}

sub is_str() {
    return sub($obj) {
        if ( ref $obj eq "" ) {
            return Ok 1;
        }
        return Err("not a string");
    }
}

sub idx($index, @checks) {
    on_array(sub($array) {
        checks($array->[$index], \@checks);
    });
}

1;
