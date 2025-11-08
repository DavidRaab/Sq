package Sq::Gen;
use 5.036;
use Sq qw(sq);
use Sq::Evaluator;
use Sq::Exporter;
our @EXPORT = (
    qw(gen),
    qw(gen_run),                                             # Runners
    qw(gen_or gen_and),                                      # Combinators
    qw(gen_array gen_repeat),                                # Array
    qw(gen_sha512 gen_str gen_str_from gen_format gen_join), # String
    qw(gen_int gen_num),                                     # Nums
);

### RUNNERS

sub gen_run($gen) {
    return sq($gen->());
}

### COMBINATORS

# Randomly picks one of @gens
sub gen_or(@gens) {
    my $count = @gens;
    return sub() {
        return $gens[rand $count]->();
    }
}

# Executes every generator and puts results into an array
sub gen_and(@gens) {
    return sub() {
        return [map { $_->() } @gens];
    }
}

### STRING

# Generates a random valid SHA512 string
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

# Generetas a random string of length $min to $max
# @chars contains the characters of the string.
sub gen_str($min, $max) {
    return sub() {
        state @chars = (
            0..9, 'a'..'z', 'A'..'Z', ' ', "\n",
            qw/+ - = ? ( ) { } [ ] < > " ' & `/
        );
        state $chars = @chars;
        my $str;
        my $diff   = $max - $min;
        my $amount = $min + (rand($diff + 1));
        for ( 1 .. $amount ) {
            $str .= $chars[rand($chars)];
        }
        return $str;
    }
}

# same as gen_str, but you can pass the characters the string should have
sub gen_str_from($min, $max, @chars) {
    return sub() {
        my $chars = @chars;
        my $str;
        my $diff   = $max - $min;
        my $amount = $min + (rand($diff + 1));
        for ( 1 .. $amount ) {
            $str .= $chars[rand($chars)];
        }
        return $str;
    }
}

sub gen_join($sep, $gen) {
    return sub() {
        return join($sep, $gen->()->@*);
    }
}

sub gen_format($format, $gen) {
    return sub() {
        my $str = $gen->();
        return sprintf($format, $str);
    }
}

### NUMBERS

# Generetas a random integer between $min and $max inclusive.
sub gen_int($min, $max) {
    return sub() {
        my $diff = $max - $min;
        return int( $min + rand($diff + 1));
    }
}

sub gen_num($min, $max) {
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