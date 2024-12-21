package Sq::Sig::Option;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

sigt('Option::Some', t_tuplev(t_array), t_opt);
# sigt('Option::None', t_tuple(),         t_opt); # doesn't work because of Prototype

sig('Option::is_some', t_any, t_bool);
sig('Option::is_none', t_any, t_bool);

# this is not "perfect" as this also would allow passing Some => ..., Some ...
# but its fine enough for a type-check because I don't plan to remove the Carp::croak
# calls in match() at the moment. But, should I?
my $case = t_enum('Some', 'None');
sig ('Option::match', t_opt, $case, t_sub, $case, t_sub, t_any);

# Still need a solution for signature with list context
# sigt('Option::or',    t_tuplev(t_opt, t_array(t_min(1), t_of(t_any))), t_any);
# sigt('Option::or_with', ...)

sig('Option::or_else',      t_opt, t_opt, t_opt);
sig('Option::or_else_with', t_opt, t_sub, t_opt);
sig('Option::bind',         t_opt, t_sub, t_opt);
sig('Option::bind2',        t_opt, t_opt,               t_sub, t_opt);
sig('Option::bind3',        t_opt, t_opt, t_opt,        t_sub, t_opt);
sig('Option::bind4',        t_opt, t_opt, t_opt, t_opt, t_sub, t_opt);
sigt('Option::bind_v',
    t_array(
        t_of (t_or(t_opt, t_sub)), # this is not completely correct. only last one is sub
        t_idx(-1, t_sub)           # expect last one as function
    ),
    t_opt
);

sig('Option::map',         t_opt, t_sub,                      t_opt);
sig('Option::map2',        t_opt, t_opt,               t_sub, t_opt);
sig('Option::map3',        t_opt, t_opt, t_opt,        t_sub, t_opt);
sig('Option::map4',        t_opt, t_opt, t_opt, t_opt, t_sub, t_opt);
sigt('Option::map_v',
    t_array(
        t_of (t_or(t_opt, t_sub)), # this is not completely correct. only last one is sub
        t_idx(-1, t_sub)           # expect last one as function
    ),
    t_opt
);

sig('Option::validate',  t_opt, t_sub,        t_opt);
sig('Option::check',     t_opt, t_sub,        t_bool);
sig('Option::fold',      t_opt, t_any, t_sub, t_any);
sig('Option::fold_back', t_opt, t_any, t_sub, t_any);
sig('Option::iter',      t_opt, t_sub,        t_void);
sig('Option::single',    t_opt,               t_opt(t_array));
sig('Option::to_array',  t_opt,               t_array);
sig('Option::to_seq',    t_opt,               t_seq);
# sig('Option::get', ... ) # list context

### Module Functions

sig('Option::is_opt',          t_any, t_any,               t_bool);
sig('Option::all_valid',       t_any, t_array(t_of t_opt), t_opt);
sig('Option::all_valid_by',    t_any, t_array, t_sub,      t_opt);
sig('Option::filter_valid',    t_any, t_array(t_of t_opt), t_array);
sig('Option::filter_valid_by', t_any, t_array, t_sub,      t_array);
# sigt('Option::extract',        t_tuplev(t_any, ), )  # list context

sigt('Array::dump',
    t_or(
        t_tuple(t_array),
        t_tuple(t_array, t_int),
        t_tuple(t_array, t_int, t_int),
    ),
    t_str
);
sigt('Array::dumpw',
    t_or(
        t_tuple(t_array),
        t_tuple(t_array, t_int),
        t_tuple(t_array, t_int, t_int),
    ),
    t_void
);

1;