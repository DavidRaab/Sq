package Result;
use 5.036;
use Carp ();
use Sub::Exporter -setup => {
    exports => [qw(Ok Err)],
    groups  => {},
};

# enum values representing Ok/Err
my $err = 0;
my $ok  = 1;

sub Ok :prototype($) ($value) {
    return bless([$ok  => $value], 'Result');
}

sub Err :prototype($) ($value) {
    return bless([$err => $value], 'Result');
}

sub is_result($any) {
    return ref $any eq 'Result' ? 1 : 0;
}

sub is_ok($any) {
    return ref $any eq 'Result' && $any->[0] == $ok ? 1 : 0;
}

sub is_err($any) {
    return ref $any eq 'Result' && $any->[0] == $err ? 1 : 0;
}

sub match($result, %args) {
    my $fOk  = $args{Ok}  or Carp::croak "Ok not defined";
    my $fErr = $args{Err} or Carp::croak "Err not defined";

    if ( $result->[0] == $ok ) {
        return $fOk->($result->[1]);
    }
    else {
        return $fErr->($result->[1]);
    }
}

sub map($result, $f) {
    return $result->[0] == $ok
         ? bless([$ok => $f->($result->[1])], 'Result')
         : $result;
}

sub mapErr($result, $f) {
    return $result->[0] == $err
         ? bless([$err => $f->($result->[1])], 'Result')
         : $result;
}

sub fold($result, $state, $f_state) {
    return $result->[0] == $ok
         ? $f_state->($result->[1], $state)
         : $state;
}

# or: Result<'a> -> 'a -> 'a
sub or($result, $default) {
    return $result->[0] == $ok ? $result->[1] : $default;
}

# or_with: Result<'a> -> (unit -> 'a) -> 'a
sub or_with($result, $f) {
    return $result->[0] == $ok ? $result->[1] : $f->();
}

# or_else: Result<'a> -> Result<'a> -> Result<'a>
sub or_else($result, $default_result) {
    return $result->[0] == $ok ? $result : $default_result;
}

# or_else_with: Result<'a> -> (unit -> Result<'a>) -> Result<'a>
sub or_else_with($result, $f_result) {
    return $result->[0] == $ok ? $result : $f_result->();
}

sub iter($result, $f) {
    $f->($result->[1]) if $result->[0] == $ok;
    return;
}

sub to_option($result) {
    return $result->[0] == $ok
         ? Option::Some($result->[1])
         : Option::None();
}

sub to_array($result) {
    return $result->[0] == $ok
         ? Array->new($result->[1])
         : Array->new();
}

1;
