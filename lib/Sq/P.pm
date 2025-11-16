package Sq::P;
use 5.036;
use Sq;
use Sq::Parser;

sub load_signature($) {
    require Sq::Sig::P;
}

sub date_ymd($) {
    state $parser = p_matchf(qr/\A(\d\d\d\d)-(\d\d)-(\d\d)\z/, sub($y,$m,$d) {
        return if $m > 12 || $m == 0;
        return if $d > 31 || $d == 0;
        return $y,$m,$d;
    });
    return $parser;
}

sub date_dmy($,$sep='.') {
    return p_matchf(qr/\A(\d\d)\Q$sep\E(\d\d)\Q$sep\E(\d\d\d\d)\z/, sub($d,$m,$y) {
        return if $m > 12 || $m == 0;
        return if $d > 31 || $d == 0;
        return $d,$m,$y;
    });
}

no Sq::Parser;

1;