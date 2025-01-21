package Sq::Collections::Hash;
package Hash;
use 5.036;
use Hash::Util ();
use subs 'bind', 'keys', 'values', 'bless', 'map', 'delete', 'length';

# TODO: equal, eual_values, is_disjoint

### CONSTRUCTORS

sub empty($) {
    return CORE::bless({}, 'Hash');
}

sub new($, @args) {
    return CORE::bless({@args}, 'Hash');
}

sub bless($, $href) {
    return CORE::bless($href, 'Hash');
}

sub locked($, $href) {
    CORE::bless($href, 'Hash');
    Hash::Util::lock_keys(%$href);
    return $href;
}

sub init($, $amount, $f) {
    my $hash = CORE::bless({}, 'Hash');
    for my $idx ( 0 .. $amount-1 ) {
        my ($k,$v) = $f->($idx);
        $hash->{$k} = $v;
    }
    return $hash;
}

sub from_array($, $array, $f) {
    my $new  = CORE::bless({}, 'Hash');
    my $stop = @$array;
    my ($k,$v);
    for (my $i=0; $i < $stop; $i++) {
        ($k,$v) = $f->($i,$array->[$i]);
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
    my ($k,$v);
    for my ($key,$value) ( %$hash ) {
        ($k, $v) = $f->($key, $value);
        $new{$k} = $v;
    }
    return CORE::bless(\%new, 'Hash');
}

sub find($hash, $predicate) {
    # IMPORTANT:
    # using 'each' causes a bug as not going through all elements does not
    # reset the internal iterator. So calling `find` multiple times on the
    # same hash leads to buggy behaviour.
    for my ($k,$v) ( %$hash ) {
        return Option::Some(CORE::bless([$k,$v], 'Array')) if $predicate->($k,$v);
    }
    return Option::None();
}

sub pick($hash, $f_opt) {
    my $opt;
    for my ($k,$v) ( %$hash ) {
        $opt = $f_opt->($k,$v);
        return $opt if @$opt;
    }
    return Option::None();
}

sub keep($hash, $predicate) {
    my %new;
    for my ($key,$value) ( %$hash ) {
        if ( $predicate->($key, $value) ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

sub fold($hash, $state, $f) {
    for my ($key,$value) ( %$hash ) {
        $state = $f->($key, $value, $state);
    }
    return $state;
}

sub fold_back($hash, $state, $f) {
    for my ($key,$value) ( %$hash ) {
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

# Hash<'a> -> ('a -> Hash<'b>) -> Hash<'b>
sub bind($hash, $f) {
    my %new;
    for my ($key,$value) ( %$hash ) {
        my $tmp_hash = $f->($key, $value);
        for my ($key,$value) ( %$tmp_hash ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

sub append($hashA, $hashB) {
    my %new = %$hashA;
    for my ($key,$value) ( %$hashB ) {
        $new{$key} = $value;
    }
    return CORE::bless(\%new, 'Hash');
}

sub union($hash, $other, $f) {
    my %new;
    for my ($key,$value) ( %$hash ) {
        $new{$key} =
            defined $other->{$key}
                ? $f->($key, $value, $other->{$key})
                : $value;
    }
    for my ($key,$value) ( %$other ) {
        if ( !defined $new{$key} ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

sub intersect($hash, $other, $f) {
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
    for my ($key,$value) ( %$hash ) {
        if ( exists $other->{$key} ) {
            $new{$key} = $f->($key, $value, $other->{$key});
        }
    }
    return CORE::bless(\%new, 'Hash');
}

# Hash<'a,'b> -> Hash<'a,'b> -> Hash<'a,'b>
sub diff($hash, $other) {
    my %new;
    for my ($key,$value) ( %$hash ) {
        if ( !defined $other->{$key} ) {
            $new{$key} = $value;
        }
    }
    return CORE::bless(\%new, 'Hash');
}

sub concat(@hashes) {
    my %new;
    for my $hash ( @hashes ) {
        for my ($key,$value) ( %$hash ) {
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
    my $array = CORE::bless([], 'Array');
    for my $key ( @keys ) {
        push @$array, Option::Some($hash->{$key});
    }
    return $array;
}

sub slice($hash, @keys) {
    my $new = CORE::bless({}, 'Hash');
    my $v;
    for my $key ( @keys ) {
        $v = $hash->{$key};
        $new->{$key} = $v if defined $v;
    }
    return $new;
}

sub with($hash, @kvs) {
    my $new = {%$hash};
    for my ($k,$v) ( @kvs ) {
        $new->{$k} = $v;
    }
    return CORE::bless($new, 'Hash');
}

sub withf($hash, %kfs) {
    my $new = {};
    my $f;
    for my ($key,$value) ( %$hash ) {
        if ( defined $value ) {
            $f = $kfs{$key};
            $new->{$key} = defined $f ? $f->($value) : $value;
        }
    }
    return CORE::bless($new, 'Hash');
}

sub has_keys($hash, @keys) {
    for my $key ( @keys ) {
        return 0 if !defined $hash->{$key};
    }
    return 1;
}

sub to_array($hash, $f) {
    my @new;
    for my ($key,$value) ( %$hash ) {
        CORE::push @new, $f->($key, $value);
    }
    return CORE::bless(\@new, 'Array');
}

#
# SIDE-EFFECTS
#

sub on($hash, %kfs) {
    for my ($key,$f) ( %kfs ) {
        my $value = $hash->{$key};
        $f->($value) if defined $value;
    }
    return;
}

sub iter($hash, $f) {
    for my ($key,$value) ( %$hash ) {
        $f->($key, $value);
    }
    return;
}

sub iter_sort($hash, $compare, $f) {
    local ($a,$b);
    for my $key ( sort { $compare->($a,$b) } CORE::keys %$hash ) {
        $f->($key, $hash->{$key});
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
    my $count = @kvs;
    for (my $idx=0; $idx < $count; $idx+=2) {
        $hash->{ $kvs[$idx] } = $kvs[$idx+1];
    }
    return;
}

sub change($hash, %kfs) {
    for my ($key,$f) ( %kfs ) {
        my $value = $hash->{$key};
        $hash->{$key} = $f->($value) if defined $value;
    }
    return;
}

sub push($hash, $key, @values) {
    my $v = $hash->{$key};
    if ( defined $v ) {
        my $ref = ref $v;
        # if Array we just push onto it
        if ( $ref eq 'Array' ) {
            CORE::push @$v, @values;
        }
        # if plain perl array then Array blessing is added.
        elsif ( $ref eq 'ARRAY' ) {
            CORE::bless($v, 'Array');
            CORE::push @$v, @values;
        }
        # otherwise we "upgrade" element to an array
        else {
            $hash->{$key} = CORE::bless([$v, @values], 'Array');
        }
    }
    # when not exists/undef, we create array
    else {
        $hash->{$key} = CORE::bless([@values], 'Array');
    }
    return;
}

sub delete($hash, @keys) {
    for my $key ( @keys ) {
        CORE::delete $hash->{$key};
    }
    return;
}

1;