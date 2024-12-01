package Sq::Parser;
use 5.036;
use Sq;
use Sub::Exporter -setup => {
    exports => [
        qw(p_run p_is p_match p_map p_bind p_and p_return),
    ],
    groups => {
        default => [qw(p_run p_is p_match p_map p_bind p_and p_return)],
    },
};

# Expects a Parser and a string and runs the parser against the string
# returning if it succedded or not.
#
# Parser<'a> -> string -> Option<[$1,$context]>
sub p_run($parser, $str) {
    $parser->(sq({ pos => 0 }), $str);
}

# monadic return. just wraps any values into an parser. Useful in bind functions.
sub p_return(@values) {
    return sub($ctx,$str) {
        return Some([$ctx,@values]);
    };
}

# matches a regex against a string. Just returns an Option if successfull or not.
sub p_is($regex) {
    return sub($context,$str) {
        pos($str) = $context->{pos};
        if ( $str =~ m/\G$regex/gc ) {
            return Some([Hash::with($context, pos => pos($str))]);
        }
        else {
            return None;
        }
    };
}

# Matches a Regex against the current position of the string. Expects that
# $regex has one capture $1 to extract
#
# Regex -> Parser<[$1,$context]>
sub p_match($regex) {
    return sub($context,$str) {
        pos($str) = $context->{pos};
        if ( $str =~ m/\G$regex/gc ) {
            return Some([Hash::with($context, pos => pos($str)), $1]);
        }
        else {
            return None;
        }
    };
}

# maps function $f against the values of the parser and returns a new parser
#
# Parser<'a> -> ('a -> 'b) -> Parser<'b>
sub p_map($parser, $f) {
    return sub($context,$str) {
        my ($is_some, $ctx, @xs) = Option->extract_array($parser->($context,$str));
        if ( $is_some ) { return Some([$ctx, $f->(@xs)]) }
        else            { return None                    }
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
        else {
            return None;
        }
    }
}

# executes multiple parsers one after another and expects every paser to be successful
# when all are successful then it return Some() result containing the matches
# of all parsers. When one parser fails it returns None.
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

1;