package Sq::Core;

package Sq::Equality;
use 5.036;
use builtin 'refaddr';

*is_num = \&Scalar::Util::looks_like_number;

# This is inlined in equal() but i still provide this function as an API
# called by other code
sub hash($hash, $other) {
    return 1 if refaddr($hash) == refaddr($other);
    my @keys = keys %$hash;
    return 0 if @keys != keys %$other;
    for my $key ( @keys ) {
        return 0 if not exists $other->{$key};
        return 0 if equal($hash->{$key}, $other->{$key}) == 0;
    }
    return 1;
}

# This is inlined in equal() but i still provide this function as an API
# called by other code
sub array($array, $other) {
    return 1 if refaddr($array) == refaddr($other);
    return 0 if @$array != @$other;
    for ( my $idx=0; $idx < @$array; $idx++ ) {
        return 0 if equal($array->[$idx], $other->[$idx]) == 0;
    }
    return 1;
}

sub seq($seq, $other) {
    return 1 if refaddr($seq) == refaddr($other);
    my $itA = $seq->();
    my $itB = $other->();
    my ($x,$y);
    NEXT:
    $x = $itA->();
    $y = $itB->();
    if ( defined $x && defined $y ) {
        return 0 if equal($x,$y) == 0;
        goto NEXT;
    }
    return 1 if !defined($x) && !defined($y);
    return 0;
}

sub result($result, $other) {
    return 1 if refaddr($result) == refaddr($other);
    return 0 if $result->[0] != $other->[0];
    return equal($result->[1], $other->[1]);
}

sub du($union, $other) {
    return equal($union->[0], $other->[0]);
}

sub du_case($union, $other) {
    if ( $union->[2] eq $other->[2] ) {
        if ( equal($union->[0], $other->[0]) ) {
            if ( equal($union->[3], $other->[3]) ) {
                return 1;
            }
        }
    }
    return 0;
}

sub path_tiny($obj, $other) {
    return 1 if $obj eq $other;
    return 0;
}

my $dispatch = {
    'Result'             => \&result,
    'Seq'                => \&seq,
    'Sq::Core::DU'       => \&du,
    'Sq::Core::DU::Case' => \&du_case,
    'Path::Tiny'         => \&path_tiny,
};

sub equal($any1, $any2) {
    if ( defined $any1 && defined $any2 ) {
        # when number
        if ( is_num($any1) && is_num($any2) ) {
            return $any1 == $any2 ? 1 : 0;
        }
        # get type of references
        my $t1 = ref $any1;
        my $t2 = ref $any2;
        # otherwise map references
        if    ( $t1 eq 'ARRAY' ) { $t1 = 'Array' }
        elsif ( $t1 eq 'HASH'  ) { $t1 = 'Hash'  }
        if    ( $t2 eq 'ARRAY' ) { $t2 = 'Array' }
        elsif ( $t2 eq 'HASH'  ) { $t2 = 'Hash'  }
        # when not the same type, not equal
        return 0 if $t1 ne $t2;
        # when string
        if ( $t1 eq '' && $t2 eq '' ) {
            return $any1 eq $any2 ? 1 : 0;
        }
        # when references are the same, abort as equal
        return 1 if refaddr($any1) == refaddr($any2);

        # otherwise compare references. Some are inlined
        if ( $t1 eq 'Array' ) {
            return 0 if @$any1 != @$any2;
            for ( my $idx=0; $idx < @$any1; $idx++ ) {
                return 0 if equal($any1->[$idx], $any2->[$idx]) == 0;
            }
            return 1;
        }
        elsif ( $t1 eq 'Hash' ) {
            my @keys = keys %$any1;
            return 0 if @keys != keys %$any2;
            for my $key ( @keys ) {
                return 0 if not exists $any2->{$key};
                return 0 if equal($any1->{$key}, $any2->{$key}) == 0;
            }
            return 1;
        }
        elsif ( $t1 eq 'Option' ) {
            return 0 if @$any1 != @$any2;
            for ( my $idx=0; $idx < @$any1; $idx++ ) {
                return 0 if equal($any1->[$idx], $any2->[$idx]) == 0;
            }
            return 1;
        }
        elsif ( $t1 eq 'Regexp' ) {
            return $any1 eq $any2 ? 1 : 0;
        }

        # dispatch all other types
        my $fn = $dispatch->{$t1};
        return 0 if !defined $fn;
        return $fn->($any1, $any2);
    }
    return 0 if defined $any1;
    return 0 if defined $any2;
    return 1;
}

sub add_equality($type, $func) {
    Carp::croak "You must provide a string" if not Sq::is_str($type);
    Carp::croak "You must provide an comparison function" if ref $func ne 'CODE';
    $dispatch->{$type} = $func;
    return;
}


package Sq::Lazy;
use 5.036;

sub lazy :prototype(&) {
    my ( $fn ) = @_;
    my $cache;
    return bless(sub {
        return $cache if !defined $fn;
        $cache = $fn->();
        $fn    = undef;
        return $cache;
    }, 'Sq::Lazy');
}

sub force($self) {
    return $self->();
}


package Sq::Copy;
use 5.036;

# As far i see Path::Tiny objects don't do mutation. All methods return new
# objects. So it should be safe to return object as-is. If I encounter a problem
# with this, this must be changed.
sub path_tiny($path) {
    return $path;
}

my $copy_dispatch = {
    'Path::Tiny' => \&path_tiny,
};

sub copy($any) {
    my $ref = ref $any;
    if ( $ref eq "" ) {
        return $any;
    }
    elsif( $ref eq 'Array' || $ref eq 'ARRAY' ) {
        my $new = bless([], 'Array');
        for my $x ( @$any ) {
            if ( defined $x ) {
                push @$new, copy($x);
            }
            else {
                return $new;
            }
        }
        return $new;
    }
    elsif ( $ref eq 'Hash' || $ref eq 'HASH' ) {
        my $new = bless({}, 'Hash');
        for my ($k,$v) ( %$any ) {
            $new->{$k} = copy($v);
        }
        return $new;
    }
    elsif ( $ref eq 'Option' ) {
        my $new = bless([], 'Option');
        for my $x ( @$any ) {
            push @$new, copy($x);
        }
        return $new;
    }
    elsif ( $ref eq 'Result' ) {
        return bless([$any->[0], copy($any->[1])], 'Result');
    }
    elsif ( $ref eq 'Seq' ) {
        return $any;
    }
    elsif ( $ref eq 'Regexp' ) {
        return $any;
    }
    else {
        my $func = $copy_dispatch->{$ref};
        if ( defined $func ) {
            return $func->($any);
        }
        Carp::croak "No copy for '$ref' defined.";
    }
}

sub add_copy($type, $func) {
    Carp::croak "You must provide a string"        if not Sq::is_str($type);
    Carp::croak "You must provide a copy function" if ref $func ne 'CODE';
    $copy_dispatch->{$type} = $func;
    return;
}

package Option;
use 5.036;
use overload q{""} => sub { Sq::Dump::option($_[0]) };

# because this value never changes, or should change, we only need one
# value of it, and we can share it. But if someone changes the None value
# it will cause serious issues.
my $None = bless([], 'Option');

# Constructor functions that are importet by Sq
sub Some(@values) {
    return $None if @values == 0;

    if ( @values == 1 ) {
        my $value = shift @values;
        return $value                    if ref $value eq 'Option';
        return bless([$value], 'Option') if defined $value;
        return $None;
    }

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
    if ( @$opt ) { return $args{Some}(@$opt) }
    else         { return $args{None}()      }
}

# or: Option<'a> -> 'a -> 'a
sub or($opt, @defaults) {
    if ( wantarray ) {
        return @$opt ? @$opt : (@defaults);
    }
    else {
        return @$opt ? $opt->[0] : $defaults[0];
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
    return Seq->from_array([@$opt]);
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

package Result;
use 5.036;
use overload q{""} => sub { Sq::Dump::result($_[0]) };

# enum values representing Ok/Err
my $err = 0;
my $ok  = 1;

sub Ok :prototype($) ($value) {
    return bless([$ok  => $value], 'Result');
}

sub Err :prototype($) ($value) {
    return bless([$err => $value], 'Result');
}

sub is_ok($any) {
    return ref $any eq 'Result' && $any->[0] == $ok ? 1 : 0;
}

sub is_err($any) {
    return ref $any eq 'Result' && $any->[0] == $err ? 1 : 0;
}

sub match($result, %args) {
    my $fOk  = $args{Ok}  or Carp::croak "Ok not defined";
    my $fErr = $args{Err} or Carp::croak "Err not defined";

    if ( $result->[0] == $ok ) {
        return $fOk->($result->[1]);
    }
    else {
        return $fErr->($result->[1]);
    }
}

sub map($result, $f) {
    return $result->[0] == $ok
         ? bless([$ok => $f->($result->[1])], 'Result')
         : $result;
}

# map2: Result<'a,'Err> -> Result<'b,'Err> -> ('a -> 'b -> 'c) -> Result<'c,'Err>
sub map2($ra, $rb, $f) {
    return $ra if $ra->[0] == $err;
    return $rb if $rb->[0] == $err;
    return bless([$ok => $f->($ra->[1], $rb->[1])], 'Result');
}

sub map3($ra, $rb, $rc, $f) {
    return $ra if $ra->[0] == $err;
    return $rb if $rb->[0] == $err;
    return $rc if $rc->[0] == $err;
    return bless([$ok => $f->($ra->[1], $rb->[1], $rc->[1])], 'Result');
}

sub map4($ra, $rb, $rc, $rd, $f) {
    return $ra if $ra->[0] == $err;
    return $rb if $rb->[0] == $err;
    return $rc if $rc->[0] == $err;
    return $rd if $rd->[0] == $err;
    return bless([$ok => $f->($ra->[1], $rb->[1], $rc->[1], $rd->[1])], 'Result');
}

sub mapErr($result, $f) {
    return $result->[0] == $err
         ? bless([$err => $f->($result->[1])], 'Result')
         : $result;
}

sub fold($result, $state, $f_state) {
    return $result->[0] == $ok
         ? $f_state->($result->[1], $state)
         : $state;
}

# or: Result<'a> -> 'a -> 'a
sub or($result, $default) {
    return $result->[0] == $ok ? $result->[1] : $default;
}

# or_with: Result<'a> -> (unit -> 'a) -> 'a
sub or_with($result, $f) {
    return $result->[0] == $ok ? $result->[1] : $f->();
}

# or_else: Result<'a> -> Result<'a> -> Result<'a>
sub or_else($result, $default_result) {
    return $result->[0] == $ok ? $result : $default_result;
}

# or_else_with: Result<'a> -> (unit -> Result<'a>) -> Result<'a>
sub or_else_with($result, $f_result) {
    return $result->[0] == $ok ? $result : $f_result->();
}

sub iter($result, $f) {
    $f->($result->[1]) if $result->[0] == $ok;
    return;
}

sub to_option($result) {
    return $result->[0] == $ok
         ? Option::Some($result->[1])
         : Option::None();
}

sub to_array($result) {
    return $result->[0] == $ok
         ? Array->bless([$result->[1]])
         : Array->empty;
}

sub value($result) {
    return $result->[1];
}

sub get($result) {
    return $result->[1];
}

1;
