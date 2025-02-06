package Sq::Core::DU;
use 5.036;

sub union(@cases) {
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

sub case($union, $case, $data) {
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

    # create union
    return bless([$def, $cases, $case, $data], 'Sq::Core::DU::Case');
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