package Sq::Evaluator;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Parser;
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

sub type($array) {
    state $table = {
        or        => \&t_or,        is         => \&t_is,
        str       => \&t_str,       enum       => \&t_enum,       match    => \&t_match,
        matchf    => \&t_matchf,    parser     => \&t_parser,     num      => \&t_num,
        int       => \&t_int,       positive   => \&t_positive,   negative => \&t_negative,
        range     => \&t_range,     opt        => \&t_opt,        hash     => \&t_hash,
        with_keys => \&t_with_keys, keys       => \&t_keys,       as_hash  => \&t_as_hash,
        array     => \&t_array,     idx        => \&t_idx,        tuple    => \&t_tuple,
        tuplev    => \&t_tuplev,    even_sized => \&t_even_sized, of       => \&t_of,
        min       => \&t_min,       max        => \&t_length,     any      => \&t_any,
        sub       => \&t_sub,       regex      => \&t_regex,      bool     => \&t_bool,
        seq       => \&t_seq,       void       => \&t_void,       result   => \&t_result,
        ref       => \&t_ref,       isa        => \&t_isa,        can      => \&t_can,
    };
    return eval_data($table, $array);
}

sub parser($array) {
    state $table = {
        match  => \&p_match,  matchf => \&p_matchf, matchf_opt => \&p_matchf_opt,
        map    => \&p_map,    bind   => \&p_bind,   and        => \&p_and,
        return => \&p_return, or     => \&p_or,     maybe      => \&p_maybe,
        join   => \&p_join,   str    => \&p_str,    strc       => \&p_strc,
        many   => \&p_many,   many0  => \&p_many0,  ignore     => \&p_ignore,
        fail   => \&p_fail,   qty    => \&p_qty,    choose     => \&p_choose,
        repeat => \&p_repeat, filter => \&p_filter, split      => \&p_split,
        delay  => \&p_delay,  not    => \&p_not,    empty      => \&p_empty,
    };
    return eval_data($table, $array);
}

1;