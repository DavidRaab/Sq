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
sub Some(@values) {
    return $None if @values == 0;

    my @new;
    for my $value ( @values ) {
        return $None if !defined $value;
        if ( ref $value eq 'Option' ) {
            return $None if @$value == 0;
            push @new, @$value;
        }
        else {
            push @new, $value;
        }
    }

    return bless(\@new, 'Option');
}

sub None :prototype() () {
    return $None;
}

### Methods

sub is_some($any) {
    return ref $any eq 'Option' && @$any ? 1 : 0;
}

sub is_none($any) {
    return ref $any eq 'Option' && @$any == 0 ? 1 : 0;
}

sub match($opt, %args) {
    my $fSome = $args{Some} or Carp::croak "Some not defined";
    my $fNone = $args{None} or Carp::croak "None not defined";
    if ( @$opt ) {
        return $fSome->(@$opt);
    }
    else {
        return $fNone->();
    }
}

# or: Option<'a> -> 'a -> 'a
sub or($opt, $default, @defaults) {
    if ( wantarray ) {
        return @$opt ? @$opt : ($default, @defaults);
    }
    else {
        return @$opt ? $opt->[0] : $default;
    }
}

# or_with: Option<'a> -> (unit -> Option<'a>) -> 'a
sub or_with($opt, $f_x) {
    if ( wantarray ) {
        return @$opt ? @$opt : $f_x->();
    }
    else {
        return @$opt ? $opt->[0] : $f_x->();
    }
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
    return @$opt ? $f->(@$opt) : $None;
}

sub bind2($optA, $optB, $f) {
    if ( @$optA && @$optB ) {
        return $f->(@$optA, @$optB);
    }
    return $None;
}

sub bind3($optA, $optB, $optC, $f) {
    if ( @$optA && @$optB && @$optC ) {
        return $f->(@$optA, @$optB, @$optC);
    }
    return $None;
}

sub bind4($optA, $optB, $optC, $optD, $f) {
    if ( @$optA && @$optB && @$optC && @$optD ) {
        return $f->(@$optA, @$optB, @$optC, @$optD);
    }
    return $None;
}

sub bind_v {
    my @opts = @_;
    my $f    = pop @opts;

    my @unpack;
    for my $opt ( @opts ) {
        if ( @$opt ) { push @unpack, @$opt }
        else         { return $None        }
    }

    return $f->(@unpack);
}

sub map($opt, $f) {
    return Some($f->(@$opt)) if @$opt;
    return $None;
}

sub map2($optA, $optB, $f) {
    if ( @$optA && @$optB ) {
        return Some($f->(@$optA, @$optB));
    }
    return $None;
}

sub map3($a, $b, $c, $f) {
    if ( @$a && @$b && @$c ) {
        return Some( $f->(@$a, @$b, @$c) );
    }
    return $None;
}

sub map4($a, $b, $c, $d, $f) {
    if ( @$a && @$b && @$c && @$d ) {
        return Some($f->(@$a, @$b, @$c, @$d));
    }
    return $None;
}

sub map_v {
    my @opts = @_;
    my $f    = pop @opts;

    my @unpack;
    for my $opt ( @opts ) {
        if ( @$opt ) { push @unpack, @$opt }
        else         { return $None        }
    }

    return Some($f->(@unpack));
}

sub validate($opt, $predicate) {
    if ( @$opt && $predicate->(@$opt) ) {
        return $opt;
    }
    return $None;
}

sub check($opt, $predicate) {
    if ( @$opt ) {
        return $predicate->(@$opt) ? 1 : 0;
    }
    return 0;
}

sub fold($opt, $state, $f) {
    return @$opt ? $f->(@$opt, $state) : $state;
}

sub fold_back($opt, $state, $f) {
    return @$opt ? $f->($state, @$opt) : $state;
}

sub iter($opt, $f) {
    $f->(@$opt) if @$opt;
    return;
}

sub single($opt) {
    my $l = @$opt;
    if ( $l == 1 ) {
        my $v    = $opt->[0];
        my $type = ref $v;
        if ( $type eq 'Array' ) {
            return $opt;
        }
        elsif ( $type eq 'ARRAY' ) {
            bless($v, 'Array');
            return $opt;
        }
        return Some(bless [$v], 'Array');
    }
    elsif ( $l > 1 ) {
        return Some(bless [@$opt], 'Array');
    }
    return $None;
}

sub to_array($opt) {
    return @$opt
         ? bless([@$opt], 'Array')
         : bless([],      'Array');
}

sub to_seq($opt) {
    return Seq->from_array($opt);
}

sub get($opt) {
    if ( wantarray ) {
        return @$opt if @$opt;
    }
    else {
        return $opt->[0] if @$opt;
    }
    die "Cannot extract value of None\n";
}

### Module Functions

sub is_opt($, $any) {
    return ref $any eq 'Option' ? 1 : 0;
}

sub all_valid($, $array_of_opt) {
    my $new = Array->new;
    for my $opt ( @$array_of_opt ) {
        if ( @$opt ) { push @$new, @$opt }
        else         { return $None      }
    }
    return bless([$new], 'Option');
}

sub all_valid_by($, $array, $f) {
    my $new = Array->new;
    for my $x ( @$array ) {
        my $opt = $f->($x);
        if ( @$opt ) { push @$new, @$opt }
        else         { return $None      }
    }
    return bless([$new], 'Option');
}

sub filter_valid($, $array_of_opt) {
    my $new = Array->new;
    for my $opt ( @$array_of_opt ) {
        push @$new, @$opt if @$opt;
    }
    return $new;
}

sub filter_valid_by($, $array, $f) {
    my $new = Array->new;
    for my $x ( @$array ) {
        my $opt = $f->($x);
        push @$new, @$opt if @$opt;
    }
    return $new;
}

sub extract($, @anys) {
    my @ret;
    for my $any ( @anys ) {
        return 0 if !defined $any;
        if ( ref $any eq 'Option' ) {
            return 0 if @$any == 0;
            push @ret, @$any;
        }
        else {
            push @ret, $any;
        }
    }
    return @ret > 0 ? (1,@ret) : 0;
}

sub dump($opt, $inline=60, $depth=0) {
    return Sq::Dump::dump($opt, $inline, $depth);
}

sub dumpw($opt, $inline=60, $depth=0) {
    Sq::Dump::dumpw($opt, $inline, $depth);
    return;
}

1;