package Hash;
use 5.036;
use Carp ();
use subs 'bind', 'keys', 'values', 'bless', 'map', 'foreach', 'delete', 'length';

# TODO: equal, eual_values, is_disjoint
#       change, push

sub empty($) {
    return CORE::bless({}, 'Hash');
}

sub new($class, @args) {
    Carp::croak("Hash->new() must be called with even-sized list.")
        if @args % 2 == 1;

    return CORE::bless({@args}, 'Hash');
}

sub bless($class, $href) {
    if ( ref $href eq 'HASH' ) {
        return CORE::bless($href, 'Hash');
    }
    else {
        Carp::croak('Hash->bless($href) must be called with hashref.');
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

# Returns the first key,value that matches a predicate, otherwise returns $default.
sub find($hash, $default, $predicate) {
    # IMPORTANT:
    # using 'each' causes a bug as not going through all elements does not
    # reset the internal iterator. So calling `find` multiple times on the
    # same hash leads to buggy behaviour.
    for my $k ( CORE::keys %$hash ) {
        my $v = $hash->{$k};
        return $k,$v if $predicate->($k,$v);
    }
    return $default;
}

# Like find. But $mapping must return an "optional". Any other value than undef
# that $mapping returns is immediately returned. If $mapping never returns
# any other value than undef, then undef is returned.
# pick is like ->find->map combined
sub pick($hash, $mapping) {
    for my $k ( CORE::keys %$hash ) {
        my $x = $mapping->($k,$hash->{$k});
        return $x if defined $x;
    }
    return undef;
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

sub length($hash) {
    return scalar (CORE::keys %$hash);
}

sub is_empty($hash) {
    return length($hash) == 0 ? 1 : 0;
}

# Iterates through a hash and passes the key & value to a function. That
# function is then expected to return another hash. All hashes are then
# combined into a single hash.
#
# Hash<'a> -> ('a -> Hash<'b>) -> Hash<'b>
sub bind($hash, $f) {
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        my $tmp_hash = $f->($key, $value);
        while ( my ($key, $value) = each %$tmp_hash ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

# appends a second hash onto the first hash, overwriting all keys that appear
# in the first one.
sub append($hash, $other) {
    state $second = sub($,$y) { return $y };
    return union($hash, $other, $second);
}

# union of two hashes, when a key exists in both hashes then both values
# are passed to function $f that then return the value that should be used.
#
# union is like adding two hashes
sub union($hash, $other, $f) {
    my %new;
    my %seen;
    while ( my ($key, $value) = each %$hash ) {
        if ( exists $other->{$key} ) {
            $seen{$key} = 1;
            $new{$key}  = $f->($value, $other->{$key});
        }
        else {
            $new{$key} = $value;
        }
    }
    while ( my ($key, $value) = each %$other ) {
        if ( not $seen{$key} ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

# returns a new hash only containg keys that appear in both hashes
sub intersection($hash, $other, $f) {
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        if ( exists $other->{$key} ) {
            $new{$key} = $f->($value, $other->{$key});
        }
    }
    return CORE::bless(\%new, 'Hash');
}

# Only returns hash entries that appear in $hash but not in $other.
# Like subtraction it removes all entries in $hash that appear in $other
#
# Hash<'a,'b> -> Hash<'a,'b> -> Hash<'a,'b>
sub difference($hash, $other) {
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        if ( not exists $other->{$key} ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

sub concat($hash, @others) {
    my %new;
    for my $hash ( $hash, @others ) {
        while ( my ($key, $value) = each %$hash ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

# checks if all keys in $hash exists in $other
sub is_subset_of($hash, $other) {
    for my $key ( CORE::keys %$hash ) {
        return 0 if not exists $other->{$key}
    }
    return 1;
}

# returns a single entry
sub get($hash, $key, $default) {
    return $hash->{$key} // $default;
}

# fetches many entries and returns it as an array, uses default value
# when entry does not exists in hash
#
# Hash<'a> -> 'a -> ListContext<'a> -> Array<'a>
sub extract($hash, $default, @keys) {
    my $array = Array->new;
    for my $key ( @keys ) {
        push @$array, ($hash->{$key} // $default);
    }
    return $array;
}

# creates a shallow copy
sub copy($hash, @keys) {
    # copy the whole hash when no keys are defined
    if ( @keys == 0 ) {
        return CORE::bless({%$hash}, 'Hash');
    }
    # otherwise copy just the keys specified in new hash
    else {
        my $new = Hash->new;
        for my $key ( @keys ) {
            $new->{$key} = $hash->{$key};
        }
        return $new;
    }
}

# like a 'set' but returns a new hash with the changes applied instead of
# mutating the hash
sub with($hash, @kvs) {
    my $new = copy($hash);
    set($new, @kvs);
    return $new;
}

# Returns a new hash by applying transform mapping functions for defined keys.
sub withf($hash, @kfs) {
    my %input = @kfs;
    my $new = Hash->new;
    for my $key ( CORE::keys %$hash ) {
        my $value = $hash->{$key};
        if ( defined $value ) {
            my $f = $input{$key};
            $new->{$key} = defined $f ? $f->($value) : $value;
        }
    }
    return $new;
}

# checks if keys exists and are defined in hash
sub has_keys($hash, @keys) {
    for my $key ( @keys ) {
        return 0 if !exists $hash->{$key} || !defined $hash->{$key};
    }
    return 1;
}

# TODO: shallow at the moment. Maybe add recursion so Hash/HASH and Array/Array
#       get compared deeply. All other references must be reference-equal
sub equal($hash, $other) {
    return 0 if ref $other ne 'Hash' && ref $other ne 'HASH';
    return 0 if length($hash) != length($other);
    for my $key ( CORE::keys %$hash ) {
        return 0 if not exists $other->{$key};
        return 0 if $hash->{$key} ne $other->{$key};
    }
    return 1;
}

#
# SIDE-EFFECTS
#

# check if $key exists and is defined, when this is the case it executes
# $f with the value for some side-effects.
sub on($hash, $key, $f) {
    if ( exists $hash->{$key} ) {
        my $value = $hash->{$key};
        $f->($value) if defined $value;
    }
    return;
}

sub iter($hash, $f) {
    while ( my ($key, $value) = each %$hash ) {
        $f->($key, $value);
    }
    return;
}

sub foreach($hash, $f) {
    while ( my ($key, $value) = each %$hash ) {
        $f->($key, $value);
    }
    return;
}

#
# MUTATION METHODS
#

# set overwrites each key with the specified values. key does not need
# to exists before setting.
sub set($hash, @kvs) {
    if ( @kvs % 2 == 0 ) {
        my $count = @kvs;
        for (my $idx=0; $idx < $count; $idx+=2) {
            $hash->{ $kvs[$idx] } = $kvs[$idx+1];
        }
    }
    else {
        Carp::croak("Hash->set expects an even number of arguments.");
    }
    return;
}

# similar to set as you set a key to a new value. But it reads the current
# value of a key and passes it to a function that then returns the new value.
sub change($hash, $key, $f, @kfs) {
    my %kfs = ($key, $f, @kfs);
    while ( my ($key, $f) = each %kfs ) {
        my $value = $hash->{$key};
        $hash->{$key} = $f->($value) if defined $value;
    }
    return;
}

# threats $key as an array and pushes a value onto it
# when it doesn't exists it creates an array, or if it is something
# different it turns it into an array.
sub push($hash, $key, $value, @values) {
    my $v = $hash->{$key};
    if ( defined $v ) {
        my $ref = ref $v;
        # if Array we just push onto it
        if ( $ref eq 'Array' ) {
            CORE::push @$v, $value, @values;
        }
        # if perl plain array addition Array blessing is added.
        elsif ( $ref eq 'ARRAY' ) {
            Array->bless($v);
            CORE::push @$v, $value, @values;
        }
        # otherwise we "upgrade" element to an array
        else {
            $hash->{$key} = Array->new($v, $value, @values);
        }
    }
    # when not exists/undef, we create array
    else {
        $hash->{$key} = Array->new($value, @values);
    }
    return;
}

sub delete($hash, $key, @keys) {
    for my $key ( $key, @keys ) {
        CORE::delete $hash->{$key};
    }
    return;
}

1;