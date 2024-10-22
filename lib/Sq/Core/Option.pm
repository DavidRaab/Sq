package Option;
use 5.036;
use Carp ();
use Sub::Exporter -setup => {
    exports => [qw(Some None)],
    groups  => {},
};

# because this value never changes, or should change, we only need one
# value of it, and we can share it. But if someone changes the None value
# it will cause serious issues.
my $None = bless([0], 'Option');

# represents the some value. Before it was the string 'Some', but comparing
# integers is faster
my $Some = 1;

# Constructor functions that are importet by Sq
sub Some :prototype($) ($value)  {
    return defined $value
         ? bless([$Some, $value], 'Option')
         : $None;
}

sub None :prototype() () {
    return $None;
}

### Methods

sub is_some($opt) { return $opt->[0] == $Some ? 1 : 0 }
sub is_none($opt) { return $opt->[0] ==     0 ? 1 : 0 }

sub match($opt, %args) {
    my $fSome = $args{Some} or Carp::croak "Some not defined";
    my $fNone = $args{None} or Carp::croak "None not defined";
    if ($opt->[0] == $Some) {
        return $fSome->($opt->[1]);
    }
    else {
        return $fNone->();
    }
}

sub or($opt, $default) {
    return $opt->[0] == $Some ? $opt->[1] : $default;
}

sub or_with($opt, $f) {
    return $opt->[0] == $Some ? $opt->[1] : $f->();
}

# bind : Option<'a> -> ('a -> Option<'b>) -> Option<'b>
sub bind($opt, $f) {
    return $opt->[0] == $Some
         ? $f->($opt->[1])
         : $None;
}

sub bind2($optA, $optB, $f) {
    if ( $optA->[0] == $Some && $optB->[0] == $Some ) {
        return $f->($optA->[1], $optB->[1]);
    }
    return $None;
}

sub bind3($optA, $optB, $optC, $f) {
    if ( $optA->[0] == $Some && $optB->[0] == $Some && $optC->[0] ) {
        return $f->($optA->[1], $optB->[1], $optC->[1]);
    }
    return $None;
}

sub bind4($optA, $optB, $optC, $optD, $f) {
    if ( $optA->[0] == $Some && $optB->[0] == $Some && $optC->[0] && $optD->[0] ) {
        return $f->($optA->[1], $optB->[1], $optC->[1], $optD->[1]);
    }
    return $None;
}

sub map($opt, $f) {
    return $opt->[0] == $Some
         ? Some( $f->($opt->[1]) )
         : $None;
}

sub map2($optA, $optB, $f) {
    if ( $optA->[0] == $Some && $optB->[0] == $Some ) {
        return Some( $f->($optA->[1], $optB->[1]) );
    }
    return $None;
}

sub map3($a, $b, $c, $f) {
    if (
           $a->[0] == $Some
        && $b->[0] == $Some
        && $c->[0] == $Some
    ) {
        return Some( $f->($a->[1], $b->[1], $c->[1]) );
    }
    return $None;
}

sub map4($a, $b, $c, $d, $f) {
    if (
           $a->[0] == $Some
        && $b->[0] == $Some
        && $c->[0] == $Some
        && $d->[0] == $Some
    ) {
        return Some( $f->($a->[1], $b->[1], $c->[1], $d->[1]) );
    }
    return $None;
}

sub validate($opt, $f) {
    if ( $opt->[0] == $Some && $f->($opt->[1]) ) {
        return $opt;
    }
    return $None;
}

sub flatten($opt) {
    my $result = $opt;
    while ( $result->[0] == $Some && ref $result->[1] eq 'Option' ) {
        $result = $result->[1];
    }
    return $result;
}

sub fold($opt, $state, $f) {
    return $opt->[0] == $Some
         ? $f->($state, $opt->[1])
         : $state;
}

sub iter($opt, $f) {
    if ( $opt->[0] == $Some ) {
        $f->($opt->[1]);
    }
    return;
}

sub to_array($opt) {
    return $opt->[0] == $Some
         ? bless([$opt->[1]], 'Array')
         : bless([],          'Array');
}

# Functions

sub all_valid($, $array_of_opt) {
    my $new = Array->new;
    for my $opt ( @$array_of_opt ) {
        if ( $opt->[0] == $Some ) {
            push @$new, $opt->[1];
        }
        else {
            return None;
        }
    }
    return Some($new);
}

sub all_valid_by($, $array, $f) {
    my $new = Array->new;
    for my $x ( @$array ) {
        my $opt = $f->($x);
        if ( $opt->[0] == $Some ) {
            push @$new, $opt->[1];
        }
        else {
            return None;
        }
    }
    return Some($new);
}

sub filter_valid($, $array_of_opt) {
    my $new = Array->new;
    for my $opt ( @$array_of_opt ) {
        if ( $opt->[0] == $Some ) {
            push @$new, $opt->[1];
        }
    }
    return $new;
}

sub filter_valid_by($, $array, $f) {
    my $new = Array->new;
    for my $x ( @$array ) {
        my $opt = $f->($x);
        if ( $opt->[0] == $Some ) {
            push @$new, $opt->[1];
        }
    }
    return $new;
}

sub get($opt) {
    if ( $opt->[0] == $Some ) {
        return $opt->[1];
    }
    die "Cannot extract value of None\n";
}

1;