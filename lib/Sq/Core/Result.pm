package Result;
use 5.036;
use Carp ();
use Sub::Exporter -setup => {
    exports => [qw(Ok Err)],
    groups  => {},
};

my $err = 0;
my $ok  = 1;

sub Ok($value) {
    return bless([$ok  => $value], 'Result');
}

sub Err($value) {
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
         ? return bless([$ok => $f->($result->[1])], 'Result')
         : $result;
}

sub mapErr($result, $f) {
    return $result->[0] == $err
         ? return bless([$err => $f->($result->[1])], 'Result')
         : $result;
}

1;
