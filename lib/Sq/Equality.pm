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
    my $type = type($any1);
    if ( $type eq type($any2) ) {
        my $fn = $dispatch->{$type};
        return 0 if !defined $fn;
        return $fn->($any1, $any2);
    }
    return 0;
}

sub add_equality($type, $func) {
    Carp::croak "You must provide a string" if not Sq::is_str($type);
    Carp::croak "You must provide an comparison function" if ref $func ne 'CODE';
    $dispatch->{$type} = $func;
    return;
}

# Add equal function to multiple packages
{
    *{Hash::equal}   = \&equal;
    *{Array::equal}  = \&equal;
    *{Option::equal} = \&equal;
    *{Result::equal} = \&equal;
    *{Seq::equal}    = \&equal;
}

1;