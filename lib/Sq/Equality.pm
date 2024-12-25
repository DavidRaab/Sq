package Sq::Equality;
use 5.036;
use Scalar::Util qw/looks_like_number/;
use Scalar::Util 'refaddr';

# This is inlined in equal() but i still provide this function as an API
# called by other code
sub hash($hash, $other) {
    return 1 if refaddr($hash) == refaddr($other);
    my @keys = keys %$hash;
    return 0 if @keys != keys %$other;
    for my $key ( @keys ) {
        return 0 if not exists $other->{$key};
        return 0 if equal($hash->{$key}, $other->{$key}) == 0;
    }
    return 1;
}

# This is inlined in equal() but i still provide this function as an API
# called by other code
sub array($array, $other) {
    return 1 if refaddr($array) == refaddr($other);
    return 0 if @$array != @$other;
    for ( my $idx=0; $idx < @$array; $idx++ ) {
        return 0 if equal($array->[$idx], $other->[$idx]) == 0;
    }
    return 1;
}

sub seq($seq, $other) {
    return 1 if refaddr($seq) == refaddr($other);
    my $itA = $seq->();
    my $itB = $other->();
    my ($x,$y);
    NEXT:
    $x = $itA->();
    $y = $itB->();
    if ( defined $x && defined $y ) {
        return 0 if equal($x,$y) == 0;
        goto NEXT;
    }
    return 1 if !defined($x) && !defined($y);
    return 0;
}

sub result($result, $other) {
    return 1 if refaddr($result) == refaddr($other);
    return 0 if $result->[0] != $other->[0];
    return equal($result->[1], $other->[1]);
}

my $dispatch = {
    'Result' => \&result,
    'Seq'    => \&seq,
};

sub equal($any1, $any2) {
    if ( defined $any1 && defined $any2 ) {
        # number check / comparison
        return $any1 == $any2 if looks_like_number($any1) && looks_like_number($any2);
        # get type of references
        my $t1 = ref $any1;
        my $t2 = ref $any2;
        if    ( $t1 eq 'ARRAY' ) { $t1 = 'Array' }
        elsif ( $t1 eq 'HASH'  ) { $t1 = 'Hash'  }
        if    ( $t2 eq 'ARRAY' ) { $t2 = 'Array' }
        elsif ( $t2 eq 'HASH'  ) { $t2 = 'Hash'  }
        # not the same refs, abort
        return 0              if $t1 ne $t2;
        # compare as string when not a reference
        return $any1 eq $any2 if $t1 eq "";
        # when references are the same, abort as equal
        return 1 if refaddr($any1) == refaddr($any2);

        # otherwise compare references. Some are inlined
        if ( $t1 eq 'Array' ) {
            return 0 if @$any1 != @$any2;
            for ( my $idx=0; $idx < @$any1; $idx++ ) {
                return 0 if equal($any1->[$idx], $any2->[$idx]) == 0;
            }
            return 1;
        }
        elsif ( $t1 eq 'Hash' ) {
            my @keys = keys %$any1;
            return 0 if @keys != keys %$any2;
            for my $key ( @keys ) {
                return 0 if not exists $any2->{$key};
                return 0 if equal($any1->{$key}, $any2->{$key}) == 0;
            }
            return 1;
        }
        elsif ( $t1 eq 'Option' ) {
            return 0 if @$any1 != @$any2;
            for ( my $idx=0; $idx < @$any1; $idx++ ) {
                return 0 if equal($any1->[$idx], $any2->[$idx]) == 0;
            }
            return 1;
        }

        # dispatch all other types
        my $fn = $dispatch->{$t1};
        return 0 if !defined $fn;
        return $fn->($any1, $any2);
    }
    return 0 if defined $any1;
    return 0 if defined $any2;
    return 1;
}

sub add_equality($type, $func) {
    Carp::croak "You must provide a string" if not Sq::is_str($type);
    Carp::croak "You must provide an comparison function" if ref $func ne 'CODE';
    $dispatch->{$type} = $func;
    return;
}

# Add equal function to other packages
*{Hash::equal}   = \&equal;
*{Array::equal}  = \&equal;
*{Option::equal} = \&equal;
*{Result::equal} = \&equal;
*{Seq::equal}    = \&equal;

1;