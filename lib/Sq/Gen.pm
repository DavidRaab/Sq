package Sq::Gen;
use 5.036;
use Sq::Exporter;
our @EXPORT = qw(gen_sha512);

sub gen_sha512() {
    state @chars = (0 .. 9, 'a' .. 'f');
    my $str;
    for ( 1 .. 128 ) {
        $str .= $chars[ rand(16) ];
    }
    return $str;
}

1;