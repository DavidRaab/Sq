package Sq::Dump;
use 5.036;

my $dispatch = {
    'Array'  => \&array,
    'ARRAY'  => \&array,
    'Hash'   => \&hash,
    'HASH'   => \&hash,
    'Option' => \&option,
};

sub quote($str) {
    $str =~ s/\r/\\r/;
    $str =~ s/\n/\\n/;
    $str =~ s/\t/\\t/;
    return $str;
};

sub compact($max, $str) {
    # replace empty string/array
    return '[]' if $str =~ m/\A\s*\[\s*\]\z/;
    return '{}' if $str =~ m/\A\s*\{\s*\}\z/;

    # get indentation length
    my $indent = $str =~ m/\A(\s+)/ ? CORE::length $1 : 0;

    # remove whitespace at start/end and replace all whitespace with
    # a single space
    my $no_ws = $str;
    $no_ws =~ s/\A\s+//;
    $no_ws =~ s/\s+\z//;
    $no_ws =~ s/\s+/ /g;

    # when $no_ws is smaller than $max we keep that string but we
    # need to add $ident again
    if ( CORE::length $no_ws <= $max ) {
        $str = (" " x $indent) . $no_ws;
    }

    return $str;
};

sub array($array, $inline=60, $depth=0) {
    my $str = "[\n";
    for my $x ( @$array ) {
        my $indent = " " x ($depth + 2);
        my $type   = ref $x;
        if ( !defined $x ) {
            $str .= $indent . 'undef' . ",\n";
        }
        elsif ( Sq::is_num($x) ) {
            $str .= $indent . $x . ",\n";
        }
        elsif ( Sq::is_str($x) ) {
            $str .= $indent . sprintf "\"%s\",\n", quote($x);
        }
        elsif ( $type eq 'Option' ) {
            $str .= $indent . option($x, $inline, $depth+2) . ",\n";
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            $str .= $indent . hash($x, $inline, $depth+2) . ",\n";
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            $str .= $indent . array($x, $inline, $depth+2) . ",\n";
        }
        else {
            $str .= $indent . "NOT_IMPLEMENTED,\n";
        }
    }
    $str =~ s/,\n\z/\n/;
    $str .= (" " x $depth) . "]";
    return compact($inline, $str);
}

sub hash($hash, $inline=60, $depth=0) {
    my $str = "{\n";
    for my $key ( sort { $a cmp $b } CORE::keys %$hash ) {
        my $indent = " " x ($depth + 2);
        my $value  = $hash->{$key};
        my $type   = ref $value;
        if ( !defined $value ) {
            $str .= $indent . sprintf "%s => undef,\n", $key;
        }
        elsif ( Sq::is_num($value) ) {
            $str .= $indent . sprintf "%s => %s,\n", $key, $value;
        }
        elsif ( Sq::is_str($value) ) {
            $str .= $indent . sprintf "%s => \"%s\",\n", $key, quote($value);
        }
        elsif ( $type eq 'Option' ) {
            $str .= $indent . sprintf "%s => %s,\n", $key, option($value, $inline, $depth+2);
        }
        elsif ( $type eq 'Hash'  || $type eq 'HASH' ) {
            $str .= $indent . sprintf "%s => %s,\n", $key, hash($value, $inline, $depth+2);
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            $str .= $indent . sprintf "%s => %s,\n", $key, array($value, $inline, $depth+2);
        }
        else {
            $str .= $indent . sprintf "%s => NOT_IMPLEMENTED,\n", $key;
        }
    }
    $str =~ s/,\n\z/\n/;
    $str .= (" " x $depth) . "}";
    return compact($inline, $str);
}

sub option($opt, $inline=60, $depth=0) {
    my $str = "";
    if ( @$opt ) {
        $str = 'Some(';

        my $x    = $opt->[0];
        my $type = ref $x;
        if ( Sq::is_num($x) ) {
            $str .= $x;
        }
        elsif ( Sq::is_str($x) ) {
            $str .= '"' . quote($x) . '"';
        }
        elsif ( $type eq 'Option' ) {
            $str .= option($x, $inline, $depth+2);
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            $str .= hash($x, $inline, $depth+2);
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            $str .= array($x, $inline, $depth+2);
        }
        else {
            $str .= "NOT_IMPLEMENTED";
        }

        $str .= ')';
    }
    else {
        $str = 'None';
    }
    return compact($inline, $str);
}

sub dump($any, $inline=60, $depth=0) {
    return $dispatch->{ref $any}($any, $inline, $depth);
}

sub dumpw($any, $inline=60, $depth=0) {
    warn $dispatch->{ref $any}($any, $inline, $depth), "\n";
}

1;