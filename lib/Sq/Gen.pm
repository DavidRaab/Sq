package Sq::Gen;
use 5.036;
use Sq;
use Sq::Evaluator;
use Sq::Exporter;
our @EXPORT = (
    qw(gen),
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

sub gen($array) {
    state $table = {
        map {
            () if substr($_, 0, 2) ne 'gen_';
            my $name = $_ =~ s/\Agen_//r;
            $name => \&$_;
        } @EXPORT
    };

    return eval_data($table, $array);
}

1;