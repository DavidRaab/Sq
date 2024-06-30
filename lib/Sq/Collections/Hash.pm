package Hash;
use 5.036;
use Carp ();
use subs 'bind', 'keys', 'values', 'bless', 'map', 'foreach', 'delete';

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
    # BUG: using each causes problems as not going through all
    #      all elements does not reset the internal iterator
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

sub count($hash) {
    return scalar (CORE::keys %$hash);
}

sub is_empty($hash) {
    return count($hash) == 0 ? 1 : 0;
}

# union of two hashes,
# a function decides which value should be picked if key exists in both hashes.
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

# Like union but value in second hash overwrites the first one
sub append($hash, $other) {
    state $second = sub($,$y) { return $y };
    return union($hash, $other, $second);
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

# Like 'set' but makes a shallow copy and returns a new Hash instead of mutating
sub with($hash, @kvs) {
    my $new = copy($hash);
    set($new, @kvs);
    return $new;
}

# considers $key as an array and pushes a value onto it
sub push($hash, $key, $value, @values) {
    if ( exists $hash->{$key} ) {
        CORE::push $hash->{$key}->@*, $value, @values;
    }
    else {
        $hash->{$key} = Array->new($value, @values);
    }
    return;
}

# reads key and pass it to function, return value replaces original value
sub change($hash, $key, $f, @kfs) {
    my %kfs = ($key, $f, @kfs);
    while ( my ($key, $f) = each %kfs ) {
        $hash->{$key} = $f->($hash->{$key});
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

sub delete($hash, $key, @keys) {
    for my $key ( $key, @keys ) {
        CORE::delete $hash->{$key};
    }
    return;
}

# check if $key exists and is defined, when this is the case it executes
# $f with the value for some side-effects.
sub on($hash, $key, $f) {
    if ( exists $hash->{$key} ) {
        my $value = $hash->{$key};
        $f->($value) if defined $value;
    }
    return;
}

# TODO: shallow at the moment. Maybe add recursion so Hash/HASH and Array/Array
#       get compared deeply. All other references must be reference-equal
sub equal($hash, $other) {
    return 0 if ref $other ne 'Hash' && ref $other ne 'HASH';
    return 0 if count($hash) != count($other);
    for my $key ( CORE::keys %$hash ) {
        return 0 if not exists $other->{$key};
        return 0 if $hash->{$key} ne $other->{$key};
    }
    return 1;
}

1;