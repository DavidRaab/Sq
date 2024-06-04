package Hash;
use 5.036;
use Carp ();
use subs 'keys', 'values', 'bless', 'map', 'foreach';

sub empty($class) {
    return CORE::bless({}, 'Hash');
}

sub new {
    my $class = shift;
    if ( @_ == 0 ) {
        return empty('Hash');
    }
    elsif ( @_ == 1 ) {
        if ( ref $_[0] eq 'HASH' ) {
            return CORE::bless($_[0], 'Hash');
        }
        else {
            Carp::croak("When Hash->new() is called with one argument, it must be a hash");
        }
    }
    else {
        if ( @_ % 2 == 0 ) {
            return CORE::bless({@_}, 'Hash');
        }
        else {
            Carp::croak("When Hash->new() is called with more than one argument, it must be an even number of arguments.");
        }
    }
}

sub bless {
    return new(@_);
}

# Adds (mutates) a hash by adding key, value
sub add($hash, @kvs) {
    if ( @kvs % 2 == 0 ) {
        my $count = @kvs;
        for (my $idx=0; $idx < $count; $idx+=2) {
            $hash->{ $kvs[$idx] } = $kvs[$idx+1];
        }
        return;
    }
    else {
        Carp::croak("Hash->add expects an even number of arguments.");
    }
}

sub keys($hash) {
    return CORE::bless([CORE::keys %$hash], 'Array');
}

sub values($hash) {
    return CORE::bless([CORE::values %$hash], 'Array');
}

sub map($hash, $f) {
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        my ($k, $v) = $f->($key, $value);
        $new{$k} = $v;
    }
    return CORE::bless(\%new, 'Hash');
}

sub filter($hash, $predicate) {
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        if ( $predicate->($key, $value) ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

sub fold($hash, $state, $f) {
    while ( my ($key, $value) = each %$hash ) {
        $state = $f->($state, $key, $value);
    }
    return $state;
}

sub count($hash) {
    return scalar (CORE::keys %$hash);
}

1;