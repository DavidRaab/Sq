package Sq::P;
use 5.036;
use Sq;
use Sq::Parser;

sub load_signature($) {
    require Sq::Sig::P;
}

sub date_ymd($) {
    state $parser = p_match(qr/\A(\d\d\d\d)-(\d\d)-(\d\d)\z/);
    return $parser;
}

1;