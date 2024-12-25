package Sq::Control::Lazy;
use 5.036;

sub lazy :prototype(&) {
    my ( $fn ) = @_;
    my $cache;
    return bless(sub {
        return $cache if !defined $fn;
        $cache = $fn->();
        $fn    = undef;
        return $cache;
    }, 'Sq::Control::Lazy');
}

sub force($self) {
    return $self->();
}

1;