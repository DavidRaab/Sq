package Hash;
use 5.036;
use subs 'bless', 'map', 'foreach';

sub bless($class, $hash) {
    return CORE::bless($hash, 'Hash');
}

sub map($hash, $f) {
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        my ($k, $v) = $f->($key, $value);
        $new{$k} = $v;
    }
    return \%new;
}

sub filter($hash, $predicate) {
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        if ( $predicate->($key, $value) ) {
            $new{$key} = $value;
        }
    }
    return \%new;
}

sub fold($hash, $state, $f) {
    while ( my ($key, $value) = each %$hash ) {
        $state = $f->($state, $key, $value);
    }
    return $state;
}

sub count($hash) {
    return scalar keys %$hash;
}

1;