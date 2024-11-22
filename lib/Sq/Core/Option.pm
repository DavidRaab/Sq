package Option;
use 5.036;
use Carp ();
use Sub::Exporter -setup => {
    exports => [qw(Some None)],
    groups  => {},
};

# because this value never changes, or should change, we only need one
# value of it, and we can share it. But if someone changes the None value
# it will cause serious issues.
my $None = bless([], 'Option');

# Constructor functions that are importet by Sq
sub Some :prototype($) ($value)  {
    return defined $value
         ? bless([$value], 'Option')
         : $None;
}

sub None :prototype() () {
    return $None;
}

### Methods

sub is_opt($, $any) {
    return ref $any eq 'Option' ? 1 : 0;
}

sub is_some($any) {
    return ref $any eq 'Option' && @$any == 1 ? 1 : 0;
}

sub is_none($any) {
    return ref $any eq 'Option' && @$any == 0 ? 1 : 0;
}

sub match($opt, %args) {
    my $fSome = $args{Some} or Carp::croak "Some not defined";
    my $fNone = $args{None} or Carp::croak "None not defined";
    if ( @$opt ) {
        return $fSome->($opt->[0]);
    }
    else {
        return $fNone->();
    }
}

# or: Option<'a> -> 'a -> 'a
sub or($opt, $default) {
    return @$opt ? $opt->[0] : $default;
}

# or_with: Option<'a> -> (unit -> Option<'a>) -> 'a
sub or_with($opt, $f_x) {
    return @$opt ? $opt->[0] : $f_x->();
}

# or_else: Option<'a> -> Option<'a> -> Option<'a>
sub or_else($opt, $default_opt) {
    return @$opt ? $opt : $default_opt;
}

# or_else_with: Option<'a> -> (unit -> Option<'a>) -> Option<'a>
sub or_else_with($opt, $fopt) {
    return @$opt ? $opt : $fopt->();
}

# bind : Option<'a> -> ('a -> Option<'b>) -> Option<'b>
sub bind($opt, $f) {
    return @$opt ? $f->($opt->[0]) : $None;
}

sub bind2($optA, $optB, $f) {
    if ( @$optA && @$optB ) {
        return $f->($optA->[0], $optB->[0]);
    }
    return $None;
}

sub bind3($optA, $optB, $optC, $f) {
    if ( @$optA && @$optB && @$optC ) {
        return $f->($optA->[0], $optB->[0], $optC->[0]);
    }
    return $None;
}

sub bind4($optA, $optB, $optC, $optD, $f) {
    if ( @$optA && @$optB && @$optC && @$optD ) {
        return $f->($optA->[0], $optB->[0], $optC->[0], $optD->[0]);
    }
    return $None;
}

sub bind_v {
    my @opts = @_;
    my $f    = pop @opts;

    my @unpack;
    for my $opt ( @opts ) {
        if ( @$opt ) {
            push @unpack, $opt->[0];
        }
        else {
            return $None;
        }
    }

    return $f->(@unpack);
}

sub map($opt, $f) {
    if ( @$opt ) {
        my $v = $f->($opt->[0]);
        return defined $v ? bless([$v],'Option') : $None;
    }
    return $None;
}

sub map2($optA, $optB, $f) {
    if ( @$optA && @$optB ) {
        my $v = $f->($optA->[0], $optB->[0]);
        return defined $v ? bless([$v],'Option') : $None;
    }
    return $None;
}

sub map3($a, $b, $c, $f) {
    if ( @$a && @$b && @$c ) {
        my $v = $f->($a->[0], $b->[0], $c->[0]);
        return defined $v ? bless([$v],'Option') : $None;
    }
    return $None;
}

sub map4($a, $b, $c, $d, $f) {
    if ( @$a && @$b && @$c && @$d ) {
        my $v = $f->($a->[0], $b->[0], $c->[0], $d->[0]);
        return defined $v ? bless([$v],'Option') : $None;
    }
    return $None;
}

sub map_v {
    my @opts = @_;
    my $f    = pop @opts;

    my @unpack;
    for my $opt ( @opts ) {
        if ( @$opt ) {
            push @unpack, $opt->[0];
        }
        else {
            return $None;
        }
    }

    return Some($f->(@unpack));
}

sub validate($opt, $predicate) {
    if ( @$opt && $predicate->($opt->[0]) ) {
        return $opt;
    }
    return $None;
}

sub check($opt, $predicate) {
    if ( @$opt ) {
        return $predicate->($opt->[0]) ? 1 : 0;
    }
    return 0;
}

sub flatten($opt) {
    my $ret = $opt;
    while ( @$ret && ref $ret->[0] eq 'Option' ) {
        $ret = $ret->[0];
    }
    return $ret;
}

sub fold($opt, $state, $f) {
    return @$opt ? $f->($opt->[0], $state) : $state;
}

sub iter($opt, $f) {
    $f->($opt->[0]) if @$opt;
    return;
}

sub to_array($opt) {
    return @$opt
         ? bless([$opt->[0]], 'Array')
         : bless([],          'Array');
}

sub get($opt) {
    return $opt->[0] if @$opt;
    die "Cannot extract value of None\n";
}

### Module Functions

sub all_valid($, $array_of_opt) {
    my $new = Array->new;
    for my $opt ( @$array_of_opt ) {
        if ( @$opt ) {
            push @$new, $opt->[0];
        }
        else {
            return $None;
        }
    }
    return bless([$new], 'Option');
}

sub all_valid_by($, $array, $f) {
    my $new = Array->new;
    for my $x ( @$array ) {
        my $opt = $f->($x);
        if ( @$opt ) {
            push @$new, $opt->[0];
        }
        else {
            return $None;
        }
    }
    return bless([$new], 'Option');
}

sub filter_valid($, $array_of_opt) {
    my $new = Array->new;
    for my $opt ( @$array_of_opt ) {
        if ( @$opt ) {
            push @$new, $opt->[0];
        }
    }
    return $new;
}

sub filter_valid_by($, $array, $f) {
    my $new = Array->new;
    for my $x ( @$array ) {
        my $opt = $f->($x);
        if ( @$opt ) {
            push @$new, $opt->[0];
        }
    }
    return $new;
}

sub dump($opt, $inline=60, $depth=0) {
    state $quote = sub($str) {
        $str =~ s/\r/\\r/;
        $str =~ s/\n/\\n/;
        $str =~ s/\t/\\t/;
        $str;
    };
    state $compact = sub($max, $str) {
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

        # replace empty string/array
        $str = '[]' if $str =~ m/\A\s*\[\s*\]\z/;
        $str = '{}' if $str =~ m/\A\s*\{\s*\}\z/;
        return $str;
    };

    my $str = "";
    if ( @$opt ) {
        $str = 'Some(';

        my $x    = $opt->[0];
        my $type = ref $x;
        if ( Sq::is_num($x) ) {
            $str .= $x;
        }
        elsif ( Sq::is_str($x) ) {
            $str .= '"' . $quote->($x) . '"';
        }
        elsif ( $type eq 'Option' ) {
            $str .= $compact->($inline, Option::dump($x, $inline, $depth+2));
        }
        elsif ( $type eq 'Hash' || $type eq 'HASH' ) {
            $str .= $compact->($inline, Hash::dump($x, $inline, $depth+2));
        }
        elsif ( $type eq 'Array' || $type eq 'ARRAY' ) {
            $str .= $compact->($inline, Array::dump($x, $inline, $depth+2));
        }
        else {
            $str .= "NOT_IMPLEMENTED";
        }

        $str .= ')';
    }
    else {
        $str = 'None';
    }
    return $compact->($inline, $str);
}

1;