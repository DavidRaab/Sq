package Sq::Dump;
use 5.036;

# Dumping functions for types
sub array($array, $inline=60, $depth=0) {
    my $str    = "[\n";
    my $indent = " " x ($depth + 2);
    for my $x ( @$array ) {
        $str .= $indent . to_string($x, $inline, $depth+2) . ",\n";
    }
    $str =~ s/,\n\z/\n/;
    $str .= (" " x $depth) . "]";
    return $str;
}

sub hash($hash, $inline=60, $depth=0) {
    my $str    = "{\n";
    my $indent = " " x ($depth + 2);
    for my $key ( sort { $a cmp $b } CORE::keys %$hash ) {
        my $value  = $hash->{$key};
        $str .= $indent . sprintf("%s => %s,\n", $key, to_string($value,$inline,$depth+2));
    }
    $str =~ s/,\n\z/\n/;
    $str .= (" " x $depth) . "}";
    return $str;
}

sub option($opt, $inline=60, $depth=0) {
    if ( @$opt ) {
        my $inner = join(',', map { to_string($_, $inline, $depth+2) } @$opt);
        return 'Some(' . $inner . ')';
    }
    return 'None';
}

sub seq($seq, $inline=60, $depth=0) {
    my $str    = "seq {\n";
    my $indent = " " x ($depth + 2);
    my $array  = $seq->to_array(21);
    my $max    = @$array == 21 ? 21 : @$array;
    # only put 20 elements into seq {} string
    for (my $idx=0; $idx < $max; $idx++ ) {
        $str .= $indent . to_string($array->[$idx] , $inline, $depth+2) . ",\n";
    }
    # when they are more than 20 elements
    if ( @$array == 21 ) {
        $str .= $indent . '...' . "\n" . $indent . "}";
    }
    else {
        $str =~ s/,\n\z/\n/;
        $str .= (" " x $depth) . '}';
    }
    return $str;
}

sub result($result, $inline=60, $depth=0) {
    my $str = $result->[0] == 1
        ? 'Ok('  . to_string($result->[1], $inline, $depth+2) . ')'
        : 'Err(' . to_string($result->[1], $inline, $depth+2) . ')';
    return $str;
}

# Dumping Logic
my $dispatch = {
    '_UNDEF'      => sub { 'undef'                        },
    '_NUM'        => sub { sprintf "%s", $_[0]            },
    '_STRING'     => sub { sprintf "\"%s\"", quote($_[0]) },
    'ARRAY'      => \&array,
    'Array'      => \&array,
    'HASH'       => \&hash,
    'Hash'       => \&hash,
    'Option'     => \&option,
    'Seq'        => \&seq,
    'Result'     => \&result,
    'CODE'       => sub { 'sub { DUMMY }' },
    'Path::Tiny' => sub { '"' . quote($_[0]->stringify) .'"' },
};

sub to_string($any, $inline=60, $depth=0) {
    my $type =
        !defined $any    ? '_UNDEF'  :
        Sq::is_num($any) ? '_NUM'    :
        Sq::is_str($any) ? '_STRING' :
        ref $any;

    my $func = $dispatch->{$type};
    return defined $func
         ? compact($inline, $func->($any, $inline, $depth))
         : "NOT_IMPLEMENTED REF: $type";
}

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
    # need to add $indent again
    if ( CORE::length $no_ws <= $max ) {
        $str = (" " x $indent) . $no_ws;
    }

    return $str;
};


sub dump($any, $inline=60, $depth=0) {
    return to_string($any, $inline, $depth);
}

sub dumpw($any, $inline=60, $depth=0) {
    warn to_string($any, $inline, $depth), "\n";
}

# Add dumping to other classes
{
    *{Array::dump}   = \&dump;
    *{Array::dumpw}  = \&dumpw;
    *{Hash::dump}    = \&dump;
    *{Hash::dumpw}   = \&dumpw;
    *{Seq::dump}     = \&dump;
    *{Seq::dumpw}    = \&dumpw;
    *{Option::dump}  = \&dump;
    *{Option::dumpw} = \&dumpw;
    *{Result::dump}  = \&dump;
    *{Result::dumpw} = \&dumpw;
}

1;