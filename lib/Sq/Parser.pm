package Sq::Parser;
use 5.036;
use Sq;
use Sub::Exporter -setup => {
    exports => [
        qw(p_run p_match p_matchf p_matchf_opt p_map p_bind p_and p_return p_or p_maybe),
        qw(p_join p_str p_strc p_many p_many0 p_ignore p_fail p_qty p_choose),
        qw(p_repeat p_filter p_split p_delay p_not),
    ],
    groups => {
        default => [
            qw(p_run p_match p_matchf p_matchf_opt p_map p_bind p_and p_return p_or p_maybe),
            qw(p_join p_str p_strc p_many p_many0 p_ignore p_fail p_qty p_choose),
            qw(p_repeat p_filter p_split p_delay p_not),
        ],
    },
};

### DS to represents pass/fail
sub pass($pos, $matches) {
    return { valid => 1, pos => $pos, matches => $matches }
}
sub fail($pos) {
    return { valid => 0, pos => $pos }
}

# Expects a Parser and a string and runs the parser against the string
# returning if it succedded or not.
#
# Parser<'a> -> string -> Option<[@matches]>
sub p_run($parser, $str) {
    my $p = $parser->({ valid => 1, pos => 0 }, $str);
    return Some($p->{matches}) if $p->{valid};
    return None;
}

# monadic return. just wraps any values into an parser. Useful in bind functions.
sub p_return(@values) {
    return sub($ctx,$str) {
        return {valid => 1, pos => $ctx->{pos}, matches => \@values};
    };
}

# returns a parser that always fails. Useful in bind functions.
sub p_fail() {
    state $fail = sub($ctx,$str) { return {valid => 0, pos => $ctx->{pos}} };
    return $fail;
}

# Matches a Regex against the current position of the string.
#
# Regex -> Parser<[$context,@matches]>
sub p_match($regex) {
    my $match = qr/\G$regex/;
    return sub($ctx,$str) {
        pos($str) = $ctx->{pos};
        if ( $str =~ m/$match/gc ) {
            return { valid => 1, pos => pos($str), matches => [@{^CAPTURE}] };
        }
        return { valid => 0, pos => $ctx->{pos} };
    };
}

# Matches a Regex against the current position of the string.
#
# Regex -> Parser<[$context,@matches]>
sub p_matchf($regex, $f_xs) {
    my $match = qr/\G$regex/;
    return sub($ctx,$str) {
        pos($str) = $ctx->{pos};
        if ( $str =~ m/$match/gc ) {
            my @xs = $f_xs->(@{^CAPTURE});
            return { valid => 1, pos => pos($str), matches => \@xs } if @xs;
        }
        return { valid => 0, pos => $ctx->{pos} };
    };
}

# Like p_match but when the regex could be matched than `$f_opt` is executed
# and expected to return an optional value. The option is used to decide if
# parsing failed or not. This way we also can additionally change the value
# in a single step without calling p_map. When it returns B<None> than parsing
# is considered as a failure
sub p_matchf_opt($regex, $f_opt_xs) {
    my $match = qr/\G$regex/;
    return sub($ctx,$str) {
        pos($str) = $ctx->{pos};
        if ( $str =~ m/$match/gc ) {
            my $opt = $f_opt_xs->(@{^CAPTURE});
            if ( @$opt ) {
                return {
                    valid   => 1,
                    pos     => pos($str),
                    matches => [@$opt],
                };
            }
        }
        return { valid => 0, pos => $ctx->{pos} };
    };
}

# maps function $f against the values of the parser and returns a new parser
#
# Parser<'a> -> ('a -> 'b) -> Parser<'b>
sub p_map($parser, $f_map) {
    return sub($ctx,$str) {
        my $p = $parser->($ctx,$str);
        if ( $p->{valid} ) {
            return {
                valid   => 1,
                pos     => $p->{pos},
                matches => [$f_map->($p->{matches}->@*)],
            };
        }
        return { valid => 0, pos => $p->{pos} };
    }
}

# Like p_map but functions $f_opt returns an optional that can decide if parsing
# was a failure or not.
sub p_choose($parser, $f_opt_array) {
    return sub($ctx,$str) {
        my $p = $parser->($ctx,$str);
        if ( $p->{valid} ) {
            my $opt = $f_opt_array->($p->{matches}->@*);
            if ( @$opt ) {
                return { valid => 1, pos => $p->{pos}, matches => $opt->[0] };
            }
        }
        return { valid => 0, pos => $ctx->{pos} };
    }
}

# executes
sub p_filter($parser, $predicate) {
    return sub($ctx,$str) {
        my $p = $parser->($ctx,$str);
        if ( $p->{valid} ) {
            return pass($p->{pos}, [grep { $predicate->($_) } $p->{matches}->@*]);
        }
        return fail($ctx->{pos});
    }
}

# Parser<'a> -> ('a -> Parser<'b>) -> Parser<'b>
sub p_bind($parser, $f) {
    return sub($ctx,$str) {
        my $p1 = $parser->($ctx,$str);
        if ( $p1->{valid} ) {
            my $parser = $f->($p1->{matches}->@*);
            my $p2     = $parser->($p1, $str);
            if ( $p2->{valid} ) {
                return {
                    valid   => 1,
                    pos     => $p2->{pos},
                    matches => $p2->{matches},
                }
            }
            return {valid => 0, pos => $ctx->{pos}};
        }
        return {valid => 0, pos => $ctx->{pos}};
    }
}

# executes multiple parsers one after another and expects every paser to be successful
# when all are successful then it return Some() result containing the matches
# of all parsers. When one parser fails it returns None.
# Regex: abc
sub p_and(@parsers) {
    return sub($ctx,$str) {
        my $last_p = $ctx;
        my ($p, @matches);
        for my $parser ( @parsers ) {
            $p = $parser->($last_p, $str);
            return {valid=>0, pos=>$ctx->{pos}} if !$p->{valid};
            $last_p = $p;
            push @matches, $p->{matches}->@*;
        }
        return {
            valid   => 1,
            pos     => $last_p->{pos},
            matches => \@matches,
        };
    };
}

# checks multiple parsers and returns the result of the first one that is
# successful. Or returns None if no one is succesfull.
# Regex: ( | | | )
sub p_or(@parsers) {
    return sub($ctx,$str) {
        my $p;
        for my $parser ( @parsers ) {
            $p = $parser->($ctx, $str);
            return $p if $p->{valid};
        }
        return fail($ctx->{pos});
    }
}

# tries to apply $parser, but $parser is optional. The parser that is returned
# is always succesfull either "eating" something from the string or not.
# Regex:?
sub p_maybe($parser) {
    return sub($ctx,$str) {
        my $p = $parser->($ctx,$str);
        return $p if $p->{valid};
        return pass($ctx->{pos}, []);
    }
}

# Concatenates all the results of the parser with string join
sub p_join($sep, $parser) {
    return sub($ctx,$str) {
        my $p = $parser->($ctx,$str);
        if ( $p->{valid} ) {
            return pass($p->{pos}, [join $sep, $p->{matches}->@*]);
        }
        return fail($ctx->{pos});
    }
}

# Splits every string-value with split
sub p_split($regex, $parser) {
    return sub($ctx,$str) {
        my $p = $parser->($ctx,$str);
        if ( $p->{valid} ) {
            return pass($p->{pos}, [map { split $regex, $_ } $p->{matches}->@*]);
        }
        return fail($ctx->{pos});
    }
}

# just parses a string - no capture
sub p_str($string) {
    return sub($ctx,$str) {
        my $length = length $string;
        if ( $string eq substr($str, $ctx->{pos}, $length) ) {
            return {
                valid   => 1,
                pos     => $ctx->{pos}+$length,
                matches => [],
            };
        }
        return {valid => 0, pos => $ctx->{pos}};
    }
}

# parses string - and captures string
sub p_strc($string) {
    return sub($ctx,$str) {
        my $length = length $string;
        if ( $string eq substr($str, $ctx->{pos}, $length) ) {
            return {
                valid   => 1,
                pos     => $ctx->{pos}+$length,
                matches => [$string],
            };
        }
        return {valid => 0, pos => $ctx->{pos}};
    }
}

# +: at least one, as much as possible
sub p_many($parser) {
    return sub($ctx,$str) {
        my (@matches, $p, $last_p);
        ($p, $last_p) = ($ctx, $ctx);

        REPEAT:
        $p = $parser->($p,$str);
        if ( $p->{valid} ) {
            $last_p = $p;
            push @matches, $p->{matches}->@*;
            goto REPEAT;
        }

        return @matches > 0
             ? pass($last_p->{pos}, \@matches)
             : fail($ctx->{pos});
    }
}

# *: zero or many times
sub p_many0($parser) {
    return sub($ctx,$str) {
        my (@matches, $p, $last_p);
        ($p, $last_p) = ($ctx, $ctx);

        REPEAT:
        $p = $parser->($p, $str);
        if ( $p->{valid} ) {
            $last_p = $p;
            push @matches, $p->{matches}->@*;
            goto REPEAT;
        }

        return pass($last_p->{pos}, \@matches);
    }
}

# quantity
sub p_qty($parser, $min, $max) {
    return sub($ctx,$str) {
        my ($p, $last_p, @matches);
        ($p, $last_p) = ($ctx, $ctx);
        my $count = 0;

        REPEAT:
        $p = $parser->($p,$str);
        if ( $p->{valid} ) {
            $count++;
            $last_p = $p;
            push @matches, $p->{matches}->@*;
            return pass($last_p->{pos}, \@matches) if $count >= $max;
            goto REPEAT;
        }
        if ( $count >= $min && $count <= $max ) {
            return pass($last_p->{pos}, \@matches);
        }
        return fail($ctx->{pos});
    }
}

# repeats $parser exactly $amount times
sub p_repeat($parser, $amount) {
    return p_qty($parser, $amount, $amount);
}

# removes matches
sub p_ignore($parser) {
    state $ctx_only = sub($array) { [$array->[0]] };
    return sub($ctx,$str) {
        my $p = $parser->($ctx,$str);
        if ( $p->{valid} ) {
            return pass($p->{pos}, []);
        }
        return $p;
    }
}

# This helps in defining recursive parsers. See: t/Parsers/02-nested-arrays.t
sub p_delay($f_parser) {
    return sub($ctx,$str) {
        return $f_parser->()($ctx,$str);
    }
}

# succeeds if the parser does not match
sub p_not($parser) {
    return sub($ctx,$str) {
        my $p = $parser->($ctx,$str);
        if ( $p->{valid} ) {
            return fail($ctx->{pos});
        }
        return pass($ctx->{pos}+1, []);
    }
}

1;