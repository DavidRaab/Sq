package Sq::Gen;
use 5.036;
use Sq;
use Sq::Exporter;
our @EXPORT = (
    qw(gen_run),              # Runners
    qw(gen_array gen_repeat), # Array
    qw(gen_sha512),           # String
);

sub gen_run($gen) {
    return sq($gen->());
}

sub gen_sha512() {
    return sub() {
        state @chars = (0 .. 9, 'a' .. 'f');
        my $str;
        for ( 1 .. 128 ) {
            $str .= $chars[ rand(16) ];
        }
        return $str;
    }
}

sub gen_array(@gens) {
    return sub() {
        return [map { $_->() } @gens];
    }
}

sub gen_repeat($amount, @gens) {
    return sub() {
        return [map { map { $_->() } @gens } 1 .. $amount];
    }
}

1;