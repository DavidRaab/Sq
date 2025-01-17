package Sq::Gen;
use 5.036;
use Sq qw(sq);
use Sq::Evaluator;
use Sq::Exporter;
our @EXPORT = (
    qw(gen),
    qw(gen_run),                         # Runners
    qw(gen_or),                          # Combinators
    qw(gen_array gen_repeat),            # Array
    qw(gen_sha512 gen_str gen_str_from), # String
    qw(gen_int gen_float),               # Nums
);

### RUNNERS

sub gen_run($gen) {
    return sq($gen->());
}

### COMBINATORS

sub gen_or(@gens) {
    my $count = @gens;
    return sub() {
        return $gens[rand $count]->();
    }
}

### STRING

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

sub gen_str($min, $max) {
    return sub() {
        state @chars = (
            0..9, 'a'..'z', 'A'..'Z', ' ', "\n",
            qw/+ - = ? ( ) { } [ ] < > " ' & `/
        );
        state $chars = @chars;
        my $str;
        my $diff   = $max - $min;
        my $amount = $min + (rand($diff));
        for ( 1 .. $amount ) {
            $str .= $chars[rand($chars)];
        }
        return $str;
    }
}

sub gen_str_from($min, $max, @chars) {
    return sub() {
        my $chars = @chars;
        my $str;
        my $diff   = $max - $min;
        my $amount = $min + (rand($diff));
        for ( 1 .. $amount ) {
            $str .= $chars[rand($chars)];
        }
        return $str;
    }
}

### NUMBERS

sub gen_int($min, $max) {
    return sub() {
        my $diff = $max - $min;
        return int( $min + rand($diff) );
    }
}

sub gen_float($min, $max) {
    return sub() {
        my $diff = $max - $min;
        return $min + rand($diff);
    }
}

### ARRAY

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


### EVALUATOR
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