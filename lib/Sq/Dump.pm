package Sq::Dump;
use 5.036;

our $SEQ_AMOUNT     = 50;
our $INLINE         = 200;
our $COLOR          = 1;

# Color Values for dumping
my  $COLOR_RESET    = "\e[m";
our $COLOR_STRING   = "\e[38;5;2m"; # green
our $COLOR_NUM      = "\e[38;5;1m"; # red
our $COLOR_HASH_KEY = "\e[38;5;4m"; # blue
our $COLOR_SPECIAL  = "\e[38;5;3m"; # yellow

# Dumping functions for types
sub array($array, $depth=0) {
    my $str    = "[\n";
    my $indent = " " x ($depth + 2);
    for my $x ( @$array ) {
        $str .= $indent . to_string($x, $depth+2) . ",\n";
    }
    $str =~ s/,\n\z/\n/;
    $str .= (" " x $depth) . "]";
    return $str;
}

sub queue($queue, $depth=0) {
    my $str    = "Queue [\n";
    my $indent = " " x ($depth + 2);
    for my $x ( @$queue ) {
        $str .= $indent . to_string($x, $depth+2) . ",\n";
    }
    $str =~ s/,\n\z/\n/;
    $str .= (" " x $depth) . "]";
    return $str;
}

sub hash($hash, $depth=0) {
    my $str    = "{\n";
    my $indent = " " x ($depth + 2);
    for my $key ( sort { $a cmp $b } CORE::keys %$hash ) {
        my $value  = $hash->{$key};
        if ( $COLOR ) {
            $str .= $indent . sprintf("$COLOR_HASH_KEY\%s$COLOR_RESET => %s,\n", $key, to_string($value,$depth+2));
        }
        else {
            $str .= $indent . sprintf("%s => %s,\n", $key, to_string($value,$depth+2));
        }
    }
    $str =~ s/,\n\z/\n/;
    $str .= (" " x $depth) . "}";
    return $str;
}

sub option($opt, $depth=0) {
    if ( @$opt ) {
        my $inner = join(',', map { to_string($_, $depth+2) } @$opt);
        return $COLOR
               ? "${COLOR_SPECIAL}Some$COLOR_RESET(" . $inner . ')'
               : "Some(" . $inner . ')';
    }
    return $COLOR
         ? $COLOR_SPECIAL . 'None' . $COLOR_RESET
         : 'None';
}

sub seq($seq, $depth=0) {
    my $str    = $COLOR ? "${COLOR_SPECIAL}seq${COLOR_RESET} {\n" : "seq {\n";
    my $indent = " " x ($depth + 2);
    my $array  = $seq->to_array($SEQ_AMOUNT+1);
    my $max    = @$array == ($SEQ_AMOUNT+1) ? $SEQ_AMOUNT : @$array;
    # only put $SEQ_AMOUNT elements into seq {} string
    for (my $idx=0; $idx < $max; $idx++ ) {
        $str .= $indent . to_string($array->[$idx], $depth+2) . ",\n";
    }
    # when they are more than 20 elements
    if ( @$array == ($SEQ_AMOUNT+1) ) {
        $str .= $indent . '...' . "\n" . $indent . "}";
    }
    else {
        $str =~ s/,\n\z/\n/;
        $str .= (" " x $depth) . '}';
    }
    return $str;
}

sub result($result, $depth=0) {
    if ( $COLOR ) {
        my $str = $result->[0] == 1
            ? "${COLOR_SPECIAL}Ok$COLOR_RESET("  . to_string($result->[1], $depth+2) . ')'
            : "${COLOR_SPECIAL}Err$COLOR_RESET(" . to_string($result->[1], $depth+2) . ')';
        return $str;
    }
    else {
        my $str = $result->[0] == 1
            ? 'Ok('  . to_string($result->[1], $depth+2) . ')'
            : 'Err(' . to_string($result->[1], $depth+2) . ')';
        return $str;
    }
}

# TODO: Allow specification of key order when dumping
sub benchmark($bench, $depth=0) {
    return hash({
        "Total Parent"        => $bench->cpu_p,
        "Total Childs"        => $bench->cpu_c,
        "Total Parent+Childs" => $bench->cpu_a,
        "Real Seconds"        => $bench->real,
        "Iterations Run"      => $bench->iters,
    }, $depth);
}

# Discriminated Union
sub du($union, $depth=0) {
    return sprintf("Union Type " . to_string($union->[0], $depth+2));
}

sub du_case($union, $depth=0) {
    return sprintf('$union->case(%s => %s)', $union->[2], to_string($union->[3], $depth+2))
}

sub datetime($dt, $depth=0) {
    return $COLOR
        ? sprintf "DateTime($COLOR_STRING\"%s\"$COLOR_RESET)", $dt->rfc3339
        : sprintf "DateTime(%s)", $dt->rfc3339;
}

### Dumping Logic

sub num {
    return $COLOR
         ? sprintf "$COLOR_NUM%s$COLOR_RESET", $_[0]
         : sprintf "%s", $_[0];
}

sub string {
    return $COLOR
         ? sprintf "$COLOR_STRING\"%s\"$COLOR_RESET", quote($_[0])
         : sprintf "\"%s\"", quote($_[0]);
}

# Dispatch Table for types
my $dispatch = {
    '_UNDEF'             => sub { 'undef'                        },
    '_NUM'               => \&num,
    '_STRING'            => \&string,
    'CODE'               => sub { 'sub { DUMMY }'                },
    'Sq::Control::Lazy'  => sub { 'lazy { DUMMY }'               },
    'Sq::Core::DU'       => \&du,
    'Sq::Core::DU::Case' => \&du_case,
    'ARRAY'              => \&array,
    'Array'              => \&array,
    'DateTime'           => \&datetime,
    'Queue'              => \&queue,
    'HASH'               => \&hash,
    'Hash'               => \&hash,
    'Option'             => \&option,
    'Seq'                => \&seq,
    'Result'             => \&result,
    'Benchmark'          => \&benchmark,
    'Path::Tiny'         => sub { 'path(' . string(quote($_[0]->stringify)) .')' },
};

sub quote($str) {
    $str =~ s/\"/\\"/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/\n/\\n/g;
    $str =~ s/\t/\\t/g;
    return $str;
};

sub compact($str) {
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
    if ( CORE::length $no_ws <= $INLINE ) {
        $str = (" " x $indent) . $no_ws;
    }

    return $str;
};

sub to_string($any, $depth=0) {
    my $type = '_UNDEF';
    if ( defined $any ) {
        $type = ref $any;
        if ( $type eq "" ) {
            $type = Sq::is_num($any) ? '_NUM' : '_STRING'
        }
    }

    my $func = $dispatch->{$type};
    return defined $func
         ? compact($func->($any, $depth))
         : "NOT_IMPLEMENTED REF: $type";
}

sub dumps($any) {
    return to_string($any, 0);
}

sub dump($any) {
    warn to_string($any, 0), "\n";
    return;
}

sub add_dump($type, $func) {
    Carp::croak "You must provide a string" if not Sq::is_str($type);
    Carp::croak "You must provide an comparison function" if ref $func ne 'CODE';
    $dispatch->{$type} = $func;
    return;
}

# Add dumping to other packages
no warnings 'once';
*{Array::dumps}             = \&dumps;
*{Array::dump}              = \&dump;
*{Hash::dumps}              = \&dumps;
*{Hash::dump}               = \&dump;
*{Seq::dumps}               = \&dumps;
*{Seq::dump}                = \&dump;
*{Option::dumps}            = \&dumps;
*{Option::dump}             = \&dump;
*{Result::dumps}            = \&dumps;
*{Result::dump}             = \&dump;
*{Sq::Control::Lazy::dumps} = \&dumps;
*{Sq::Control::Lazy::dump}  = \&dump;

1;