package Sq::Core::DU;
use 5.036;

### CONSTRUCTOR

sub union(@args) {
    my @cases;
    # Allow empty cases
    my ($idx,$case,$next) = (0);
    while ( $idx < @args ) {
        $case = $args[$idx];
        $next = $args[$idx+1];
        # When next is not a ref, we assume we have an empty case
        if ( ref $next eq "" ) {
            push @cases, $case, ['void'];
            $idx += 1;
        }
        # otherwise we assume we have CASE => DEF
        else {
            push @cases, $case, $next;
            $idx  += 2;
        }
    }

    # check if @cases is correct
    for my ($case,$array) ( @cases ) {
        goto ERROR if ref $case  ne "";
        goto ERROR if ref $array ne 'Array' && ref $array ne 'ARRAY';
    }
    # Create type
    my %cases;
    for my ($case,$type) ( @cases ) {
        $cases{$case} = Sq::Type::type($type);
    }
    # return object
    return bless([{@cases}, \%cases], 'Sq::Core::DU');

    ERROR:
    Carp::croak "union() must be called with 'string => type'";
}

### METHODS

sub case($union, $case, $data=undef) {
    my ($def, $cases) = @$union;
    my $type = $cases->{$case};

    # check if $case is valid
    if ( !defined $type ) {
        my $cases = join(",", keys %$cases);
        my $msg   = sprintf("Case '%s' invalid: Valid cases are '%s'", $case, $cases);
        Carp::croak $msg;
    }

    # check if $data is valid for $case
    my $result = Sq::Type::t_run($type, $data);
    if ( $result->is_err ) {
        my $msg = sprintf("Data for case '%s' invalid Expected: %s Got: %s",
            $case,
            Sq::Dump::dumps($union->[0]),
            Sq::Dump::dumps($data),
        );
        Carp::croak $msg;
    }

    # create case
    return bless([$def, $cases, $case, $data], 'Sq::Core::DU::Case');
}

sub is_case($union, $case) {
    my ($def, $cases) = @$union;
    if ( ref $case eq 'Sq::Core::DU::Case' ) {
        if ( exists $union->[1]{$case->[2]} ) {
            if ( Sq::Equality::equal($union->[0], $case->[0]) ) {
                return 1;
            }
        }
    }
    return 0;
}

sub install($union) {
    my ($pkg) = caller;
    for my $case ( keys $union->[0]->%* ) {
        my $full = $pkg . '::' . $case;
        Sq::Reflection::set_func($full, sub {
            return $union->case($case, @_);
        });
    }
    return;
}

package Sq::Core::DU::Case;
use 5.036;

sub match($union, %cf) {
    my ($def, $cases, $case, $data) = @$union;
    # check if user provided a match for every case
    for my $case ( keys %$cases ) {
        if ( !exists $cf{$case} ) {
            Carp::croak(sprintf("Case '%s' not handled", $case));
        }
    }
    # dispatch
    return $cf{$case}->($data);
}

1;