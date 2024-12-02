package Hash;
use 5.036;
use Hash::Util ();
use Carp ();
use subs 'bind', 'keys', 'values', 'bless', 'map', 'foreach', 'delete', 'length';

# TODO: equal, eual_values, is_disjoint

### CONSTRUCTORS

sub empty($) {
    return CORE::bless({}, 'Hash');
}

sub new($, @args) {
    Carp::croak("Hash->new() must be called with even-sized list.")
        if @args % 2 == 1;

    return CORE::bless({@args}, 'Hash');
}

sub bless($, $href) {
    if ( ref $href eq 'HASH' ) {
        return CORE::bless($href, 'Hash');
    }
    else {
        Carp::croak('Hash->bless($href) must be called with hashref.');
    }
}

sub locked($, $href) {
    CORE::bless($href, 'Hash');
    Hash::Util::lock_keys(%$href);
    return $href;
}

sub init($, $amount, $f) {
    my $hash = new('Hash');
    for my $idx ( 0 .. $amount-1 ) {
        my ($k,$v) = $f->($idx);
        $hash->{$k} = $v;
    }
    return $hash;
}

sub from_array($, $array, $f) {
    my $new  = new('Hash');
    my $stop = @$array;
    for (my $i=0; $i < $stop; $i++) {
        my ($k,$v) = $f->($i,$array->[$i]);
        $new->{$k} = $v;
    }
    return $new;
}

### METHODS

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

sub find($hash, $predicate) {
    # IMPORTANT:
    # using 'each' causes a bug as not going through all elements does not
    # reset the internal iterator. So calling `find` multiple times on the
    # same hash leads to buggy behaviour.
    for my $k ( CORE::keys %$hash ) {
        my $v = $hash->{$k};
        return Option::Some(Array->new($k,$v)) if $predicate->($k,$v);
    }
    return Option::None();
}

sub pick($hash, $f_opt) {
    for my $k ( CORE::keys %$hash ) {
        my $opt = $f_opt->($k,$hash->{$k});
        return $opt if Option::is_some($opt);
    }
    return Option::None();
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
        $state = $f->($key, $value, $state);
    }
    return $state;
}

sub length($hash) {
    return scalar (CORE::keys %$hash);
}

sub is_empty($hash) {
    return length($hash) == 0 ? 1 : 0;
}

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

sub append($hashA, $hashB) {
    my %new = %$hashA;
    while ( my ($key,$value) = each %$hashB ) {
        $new{$key} = $value;
    }
    return CORE::bless(\%new, 'Hash');
}

sub union($hash, $other, $f) {
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        $new{$key} =
            exists $other->{$key}
                ? $f->($key, $value, $other->{$key})
                : $value;
    }
    while ( my ($key, $value) = each %$other ) {
        if ( not exists $new{$key} ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

sub intersection($hash, $other, $f) {
    # $hash is the hash that is iterated, for performance reasons
    # it is useful to iterate the hash that has fewer keys. So we check
    # if $other has less keys and swap the hashes if that is true.
    if ( length($other) < length($hash) ) {
        my $tmp = $hash;
        $hash  = $other;
        $other = $tmp;
    }

    # build intersection
    my %new;
    while ( my ($key, $value) = each %$hash ) {
        if ( exists $other->{$key} ) {
            $new{$key} = $f->($key, $value, $other->{$key});
        }
    }
    return CORE::bless(\%new, 'Hash');
}

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

sub is_subset_of($hash, $other) {
    for my $key ( CORE::keys %$hash ) {
        return 0 if not exists $other->{$key}
    }
    return 1;
}

sub get($hash, $key) {
    my $value = $hash->{$key};
    return $value if ref $value eq 'Option';
    return Option::Some($value);
}

sub copy($hash) {
    return CORE::bless({%$hash}, 'Hash');
}

# Hash<'a> -> ListContext<string> -> Array<Option<'a>>
sub extract($hash, @keys) {
    my $array = Array->new;
    for my $key ( @keys ) {
        push @$array, Option::Some($hash->{$key});
    }
    return $array;
}

sub slice($hash, @keys) {
    my $new = Hash->new;
    for my $key ( @keys ) {
        my $v = $hash->{$key};
        $new->{$key} = $v if defined $v;
    }
    return $new;
}

sub with($hash, @kvs) {
    my $new = copy($hash);
    set($new, @kvs);
    return $new;
}

sub withf($hash, %kfs) {
    my $new   = Hash->new;
    for my $key ( CORE::keys %$hash ) {
        my $value = $hash->{$key};
        if ( defined $value ) {
            my $f = $kfs{$key};
            $new->{$key} = defined $f ? $f->($value) : $value;
        }
    }
    return $new;
}

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

sub to_array($hash, $f) {
    my $a = Array->new;
    while ( my ($key, $value) = each %$hash ) {
        CORE::push @$a, $f->($key, $value);
    }
    return $a;
}

#
# SIDE-EFFECTS
#

sub on($hash, %kfs) {
    for my $key ( CORE::keys %kfs ) {
        my $value = $hash->{$key};
        if ( defined $value ) {
            $kfs{$key}($value);
        }
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

sub lock($hash, @keys) {
    return Hash::Util::lock_keys_plus(%$hash, @keys);
}

#
# MUTATION METHODS
#

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

sub change($hash, %kfs) {
    while ( my ($key, $f) = each %kfs ) {
        my $value = $hash->{$key};
        $hash->{$key} = $f->($value) if defined $value;
    }
    return;
}

sub push($hash, $key, $value, @values) {
    my $v = $hash->{$key};
    if ( defined $v ) {
        my $ref = ref $v;
        # if Array we just push onto it
        if ( $ref eq 'Array' ) {
            CORE::push @$v, $value, @values;
        }
        # if perl plain array then Array blessing is added.
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

sub dump($hash, $inline=60, $depth=0) {
    return Sq::Dump::dump($hash, $inline, $depth);
}

sub dumpw($hash, $inline=60, $depth=0) {
    Sq::Dump::dumpw($hash, $inline, $depth);
    return;
}

1;