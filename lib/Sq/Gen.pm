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

# Sq::Gen currently is also just a Combinator. This means all functions
# just return new functions that can be executed. A Combinator is a way to
# combine functions. Consider that even a "normal" programming language like
# Perl can be seen as a combinator. For example the ";" can be seen as a
# combinator that says: Runs this function, don't care what it returns,
# then run the next function.
#
# But there are other ways to combine functions. When functions stick to a
# certain input/output data-type, you can do lots of useful stuff.
#
# For example calling `gen_int(1,100)` does not immediately generate a
# random number from 1-100. It returns a function that when is called
# will return a number from 1-100. So theoretically you must do.
#
# my $func       = gen_int(1,100);
# my $random_int = $func->();
#
# But instead of doing this manually, we use gen_run() that does this
# executing for us. Why this extra step of returning a function you may ask?
#
# because then we can combine functions. Hence the name "Combinators".
#
# for example gen_and() just takes multiple generators. just executes them,
# and puts all what those functions return into an array. So you can write.
#
#    my $dmy = gen_and(
#        gen_int(1,28),
#        gen_int(1,12),
#        gen_int(0,3000),
#    );
#
# and $dmy is, not an array. but will be another combinator, a function that
# when you execute it, returns an array with 3 numbers. You can run this combinator
# or again combain the result with another combinator. For example, you also
# can say that you want 100 of those above. So there is a gen_repeat() that does
# this task.
#
# my $hundred = gen_repeat(100, $dmy);
#
# Again, $hundreds is now a function that when is executed will return one array
# that contain hundreds inner arrays containing 3 values.
#
# [
#   [ 10,  7, 1149 ],
#   [ 21, 10, 1059 ],
#   [  3,  4, 1949 ],
#   [ 14,  8, 2799 ],
#   [ 22,  8, 1767 ],
#   [ 26, 10, 1211 ],
#   [  8, 10, 2953 ],
#   [ 12,  7,  739 ],
#   [ 10, 10, 2990 ],
# ....
#
# Combinators are awesome. They are actually pretty easy once you get the
# fundemantal understanding, and they allow for a DSL Like language
# inside a programming language that nearly describe itself. Also Sq::Type
# and Sq::Parser are based on Combinators.
#
# The only requirement for a Generator is that it is a function with no argument
# returning something. That's it.

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