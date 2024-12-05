package Sq::Parser;
use 5.036;
use Sq;
use Sub::Exporter -setup => {
    exports => [
        qw(p_run p_match p_matchf p_map p_bind p_and p_return p_or p_maybe),
        qw(p_join p_str p_strc p_many p_many0 p_ignore p_fail p_qty p_choose),
        qw(p_repeat p_filter p_split p_delay),
    ],
    groups => {
        default => [
            qw(p_run p_match p_matchf p_map p_bind p_and p_return p_or p_maybe),
            qw(p_join p_str p_strc p_many p_many0 p_ignore p_fail p_qty p_choose),
            qw(p_repeat p_filter p_split p_delay),
        ],
    },
};

# Expects a Parser and a string and runs the parser against the string
# returning if it succedded or not.
#
# Parser<'a> -> string -> Option<[@matches]>
sub p_run($parser, $str) {
    $parser->(sq({ pos => 0 }), $str)->map(sub($args) { Array::skip($args,1) });
}

# monadic return. just wraps any values into an parser. Useful in bind functions.
sub p_return(@values) {
    return sub($ctx,$str) {
        return Some([$ctx,@values]);
    };
}

# returns a parser that always fails. Useful in bind functions.
sub p_fail() {
    state $fail = sub($ctx,$str) { return None };
    return $fail;
}

# Matches a Regex against the current position of the string.
#
# Regex -> Parser<[$context,@matches]>
sub p_match($regex) {
    return sub($context,$str) {
        pos($str) = $context->{pos};
        if ( $str =~ m/\G$regex/gc ) {
            return Some([Hash::with($context, pos => pos($str)), @{^CAPTURE}]);
        }
        return None;
    };
}

# Like p_match but when the regex could be matched than `$f_opt` is executed
# and expected to return an optional value. The option is used to decide if
# parsing failed or not. This way we also can additionally change the value
# in a single step without calling p_map. When it returns B<None> than parsing
# is considered as a failure
sub p_matchf($regex, $f_opt_array) {
    return sub($ctx,$str) {
        pos($str) = $ctx->{pos};
        if ( $str =~ m/\G$regex/gc ) {
            my ($is_some, @xs) = Option->extract_array($f_opt_array->(@{^CAPTURE}));
            if ( $is_some ) {
                return Some([Hash::with($ctx, pos => pos($str)), @xs]);
            }
        }
        return None;
    };
}

# maps function $f against the values of the parser and returns a new parser
#
# Parser<'a> -> ('a -> 'b) -> Parser<'b>
sub p_map($parser, $f_map) {
    return sub($context,$str) {
        my ($is_some, $ctx, @xs) = Option->extract_array($parser->($context,$str));
        return Some([$ctx, $f_map->(@xs)]) if $is_some;
        return None;
    }
}

# Like p_map but functions $f_opt returns an optional that can decide if parsing
# was a failure or not.
sub p_choose($parser, $f_opt_array) {
    return sub($context,$str) {
        my ($is_some, $ctx, @xs) = Option->extract_array($parser->($context,$str));
        if ( $is_some ) {
            ($is_some, @xs) = Option->extract_array($f_opt_array->(@xs));
            if ( $is_some ) {
                return Some([$ctx, @xs]);
            }
        }
        return None;
    }
}

# executes
sub p_filter($parser, $predicate) {
    return sub($context,$str) {
        my ($is_some, $ctx, @xs) = Option->extract_array($parser->($context,$str));
        if ( $is_some ) {
            return Some([$ctx, grep { $predicate->($_) } @xs]);
        }
        return None;
    }
}

# Parser<'a> -> ('a -> Parser<'b>) -> Parser<'b>
sub p_bind($parser, $f) {
    return sub($context,$str) {
        my ($is_some, $ctxA, @as) = Option->extract_array($parser->($context,$str));
        if ( $is_some ) {
            my $p = $f->(@as);
            my ($is_some, $ctxB, @bs) = Option->extract_array($p->($ctxA, $str));
            return $is_some
                 ? Some([$ctxB, @bs])
                 : None;
        }
        return None;
    }
}

# executes multiple parsers one after another and expects every paser to be successful
# when all are successful then it return Some() result containing the matches
# of all parsers. When one parser fails it returns None.
# Regex: abc
sub p_and(@parsers) {
    return sub($ctx,$str) {
        my $last_ctx = $ctx;
        my (@results, $is_some, @xs);
        for my $p ( @parsers ) {
            ($is_some, $last_ctx, @xs) = Option->extract_array($p->($last_ctx, $str));
            return None if !$is_some;
            push @results, @xs;
        }
        return Some([$last_ctx, @results]);
    };
}

# checks multiple parsers and returns the result of the first one that is
# successful. Or returns None if no one is succesfull.
# Regex: ( | | | )
sub p_or(@parsers) {
    return sub($ctx,$str) {
        for my $p ( @parsers ) {
            my $opt = $p->($ctx, $str);
            return $opt if @$opt;
        }
        return None;
    }
}

# tries to apply $parser, but $parser is optional. The parser that is returned
# is always succesfull either "eating" something from the string or not.
# Regex:?
sub p_maybe($parser) {
    return sub($ctx,$str) {
        my $opt = $parser->($ctx,$str);
        return $opt if @$opt;
        return Some([$ctx]);
    }
}

# Concatenates all the results of the parser with string join
sub p_join($sep, $parser) {
    return sub($ctx,$str) {
        my ($is_some, $c, @strs) = Option->extract_array($parser->($ctx,$str));
        return $is_some
             ? Some([$c, join($sep,@strs)])
             : None;
    }
}

# Splits every string-value with split
sub p_split($regex, $parser) {
    return sub($ctx,$str) {
        my ($is_some, $c, @strs) = Option->extract_array($parser->($ctx,$str));
        return $is_some
             ? Some([$c, map { split $regex, $_ } @strs])
             : None;
    }
}

# just parses a string - no capture
sub p_str($string) {
    return sub($ctx,$str) {
        my $length = length $string;
        if ( $string eq substr($str, $ctx->{pos}, $length) ) {
            return Some([
                Hash::withf($ctx, pos => sub($pos){ $pos + $length})
            ]);
        }
        return None;
    }
}

# parses string - and captures string
sub p_strc($string) {
    return sub($ctx,$str) {
        my $length = length $string;
        if ( $string eq substr($str, $ctx->{pos}, $length) ) {
            return Some([
                Hash::withf($ctx, pos => sub($pos){ $pos + $length}),
                $string
            ]);
        }
        return None;
    }
}

# +: at least one, as much as possible
sub p_many($parser) {
    return sub($ctx,$str) {
        my ($is_some, $last_ctx, @matches, @xs);
        $last_ctx = $ctx;
        REPEAT:
        ($is_some, $ctx, @xs) = Option->extract_array($parser->($ctx,$str));
        if ( $is_some ) {
            $last_ctx = $ctx;
            push @matches, @xs;
            goto REPEAT;
        }
        return @matches > 0
             ? Some([$last_ctx, @matches])
             : None;
    }
}

# *: zero or many times
sub p_many0($parser) {
    return sub($ctx,$str) {
        my ($is_some, $last_ctx, @matches, @xs);
        $last_ctx = $ctx;
        REPEAT:
        ($is_some, $ctx, @xs) = Option->extract_array($parser->($ctx,$str));
        if ( $is_some ) {
            $last_ctx = $ctx;
            push @matches, @xs;
            goto REPEAT;
        }
        return Some([$last_ctx, @matches]);
    }
}

# quantity
sub p_qty($parser, $min, $max) {
    return sub($ctx,$str) {
        my ($is_some, $last_ctx, $count, @matches, @xs);
        $last_ctx = $ctx;
        $count    = 0;
        REPEAT:
        ($is_some, $ctx, @xs) = Option->extract_array($parser->($ctx,$str));
        if ( $is_some ) {
            $count++;
            $last_ctx = $ctx;
            push @matches, @xs;
            return Some([$last_ctx, @matches]) if $count >= $max;
            goto REPEAT;
        }
        if ( $count >= $min && $count <= $max ) {
            return Some([$last_ctx, @matches]);
        }
        return None;
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
        $parser->($ctx,$str)->map($ctx_only);
    }
}

# This helps in defining recursive parsers. See: t/Parsers/02-nested-arrays.t
sub p_delay($f_parser) {
    return sub($ctx,$str) {
        return $f_parser->()($ctx,$str);
    }
}

1;