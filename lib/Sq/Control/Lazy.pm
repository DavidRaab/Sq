package Sq::Control::Lazy;
use 5.036;

sub lazy :prototype(&) {
    return bless([$_[0]], 'Sq::Control::Lazy');
}

sub force($self) {
    return $self->[1] if @$self >= 2;
    # execute function and save result
    $self->[1] = $self->[0]();
    # delete function from slot 0. This frees the subroutine and all it's
    # memory/closure attached to it.
    $self->[0] = 0;
    return $self->[1];
}

1;