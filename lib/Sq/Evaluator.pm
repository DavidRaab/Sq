package Sq::Evaluator;
use 5.036;
use Carp ();

sub eval_data($table, $array) {
    my ($func, @rest ) = @$array;
    my @args;
    for my $rest ( @rest ) {
        if ( ref $rest eq 'Array' || ref $rest eq 'ARRAY' ) {
            push @args, eval_data($table, $rest);
        }
        else {
            push @args, $rest;
        }
    }
    my $fn = $table->{$func};
    if ( defined $fn ) {
        return $fn->(@args);
    }
    else {
        Carp::croak "No function for '$func'\n";
    }
}

1;