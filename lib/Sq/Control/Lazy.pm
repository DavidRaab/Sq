package Sq::Control::Lazy;
use 5.036;

sub lazy :prototype(&) {
    return bless([$_[0]], 'Sq::Control::Lazy');
}

sub force($self) {
    return $self->[1] if @$self == 2;
    return $self->[1] = $self->[0]();
}

1;