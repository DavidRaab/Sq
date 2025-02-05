package Sq::Core::DU;
use 5.036;

sub union(%cases) {
    for my ($case,$sub) ( %cases ) {
        goto ERROR if ref $case ne "";
        goto ERROR if ref $sub  ne 'CODE';
    }
    return bless({
        cases => \%cases,
        case  => undef,
        data  => undef,
    }, 'Sq::Core::DU');

    ERROR:
    Carp::croak "union() must be called with 'string => type'";
}

sub case($union, $case, $data) {
    # check if $case is valid
    if ( !exists $union->{cases}{$case} ) {
        my $cases = join(",", keys $union->{cases}->%*);
        my $msg   = sprintf("Case '%s' invalid: Valid cases are '%s'", $case, $cases);
        Carp::croak $msg;
    }

    # check if $data is valid for $case
    my $result = Sq::Type::t_run($union->{cases}{$case}, $data);
    if ( $result->is_err ) {
        my $msg = sprintf("Data for case '%s' invalid Got: %s", $case, Sq::Dump::dumps($data));
        Carp::croak $msg;
    }

    # create union
    return bless({
        cases => $union->{cases},
        case  => $case,
        data  => $data,
    }, 'Sq::Core::DU');
}

sub match($union, %cf) {
    my $cases = $union->{cases};
    # check if user provided a match for every case
    for my $case ( keys %$cases ) {
        if ( !exists $cf{$case} ) {
            Carp::croak(sprintf("Case '%s' not handled", $case));
        }
    }
    # dispatch
    return $cf{$union->{case}}->($union->{data});
}

1;