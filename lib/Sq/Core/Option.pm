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
sub Some($value) {
    return defined $value
         ? bless([$Some, $value], 'Option')
         : $None;
}
sub None() {
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
    return $opt->[0] == $Some ? $f->($opt->[1]) : $None;
}

sub map($opt, $f) {
    return $opt->[0] == $Some
         ? Some( $f->($opt->[1]) )
         : $None;
}

sub map2($a, $b, $f) {
    if ( $a->[0] == $Some && $b->[0] == $Some ) {
        return Some( $f->($a->[1], $b->[1]) );
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

1;