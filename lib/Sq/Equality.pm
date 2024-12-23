package Sq::Equality;
use 5.036;
use Scalar::Util qw/looks_like_number/;
use builtin 'refaddr';

sub hash($hash, $other) {
    return 1 if refaddr($hash) == refaddr($other);
    return 0 if keys %$hash != keys %$other;
    for my $key ( keys %$hash ) {
        return 0 if not exists $other->{$key};
        return 0 if equal($hash->{$key}, $other->{$key}) == 0;
    }
    return 1;
}

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

sub option($opt, $other) {
    return 1 if refaddr($opt) == refaddr($other);
    return 0 if @$opt != @$other;
    for ( my $idx=0; $idx < @$opt; $idx++ ) {
        return 0 if equal($opt->[$idx], $other->[$idx]) == 0;
    }
    return 1;
}

sub result($result, $other) {
    return 1 if refaddr($result) == refaddr($other);
    return 0 if $result->[0] != $other->[0];
    return equal($result->[1], $other->[1]);
}

my $dispatch = {
    '_UNDEF'  => sub { 1              },
    '_NUM'    => sub { $_[0] == $_[1] },
    '_STRING' => sub { $_[0] eq $_[1] },
    'Hash'    => \&hash,
    'Array'   => \&array,
    'Option'  => \&option,
    'Result'  => \&result,
    'Seq'     => \&seq,
};

sub type($any) {
    return '_UNDEF'  if !defined $any;
    return '_NUM'    if looks_like_number($any);
    my $type = ref $any;
    return '_STRING' if $type eq "";
    return 'Array'   if $type eq 'Array' || $type eq 'ARRAY';
    return 'Hash'    if $type eq 'Hash'  || $type eq 'HASH';
    return $type;
}

sub equal($any1, $any2) {
    if ( defined $any1 && defined $any2 ) {
        return $any1 == $any2 if looks_like_number($any1) && looks_like_number($any2);
        my $t1 = ref $any1;
        my $t2 = ref $any2;
        if    ( $t1 eq 'ARRAY' ) { $t1 = 'Array' }
        elsif ( $t1 eq 'HASH'  ) { $t1 = 'Hash'  }
        if    ( $t2 eq 'ARRAY' ) { $t2 = 'Array' }
        elsif ( $t2 eq 'HASH'  ) { $t2 = 'Hash'  }

        if ( $t1 eq $t2 ) {
            if ( $t1 eq '' ) {
                return $any1 eq $any2;
            }
            elsif ( $t1 eq 'Array' ) {
                return 1 if refaddr($any1) == refaddr($any2);
                return 0 if @$any1 != @$any2;
                for ( my $idx=0; $idx < @$any1; $idx++ ) {
                    return 0 if equal($any1->[$idx], $any2->[$idx]) == 0;
                }
                return 1;
            }
            elsif ( $t1 eq 'Hash' ) {
                return 1 if refaddr($any1) == refaddr($any2);
                return 0 if keys %$any1 != keys %$any2;
                for my $key ( keys %$any1 ) {
                    return 0 if not exists $any2->{$key};
                    return 0 if equal($any1->{$key}, $any2->{$key}) == 0;
                }
                return 1;
            }
            # all other types
            else {
                my $fn = $dispatch->{$t1};
                return 0 if !defined $fn;
                return $fn->($any1, $any2);
            }
        }
        return 0;
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