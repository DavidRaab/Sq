package Sq::Sig::Option;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $any  = t_any;
my $opt  = t_opt;
my $aopt = t_array(t_of $opt);


sigt('Option::Some', t_tuplev(t_array), $opt);
# sigt('Option::None', t_tuple(),         $opt); # doesn't work because of Prototype

sig('Option::is_some', $any, t_bool);
sig('Option::is_none', $any, t_bool);

my $matches = t_keys(
    Some => t_sub,
    None => t_sub,
);
sigt('Option::match', t_tuplev($opt, t_as_hash($matches)), $any);

# Still need a solution for signature with list context
# sigt('Option::or',    t_tuplev($opt, t_array(t_min(1), t_of($any))), $any);
# sigt('Option::or_with', ...)

sig('Option::or_else',      $opt, $opt,                    $opt);
sig('Option::or_else_with', $opt, t_sub,                   $opt);
sig('Option::bind',         $opt, t_sub,                   $opt);
sig('Option::bind2',        $opt, $opt,             t_sub, $opt);
sig('Option::bind3',        $opt, $opt, $opt,       t_sub, $opt);
sig('Option::bind4',        $opt, $opt, $opt, $opt, t_sub, $opt);
sigt('Option::bind_v',
    t_array(
        t_of (t_or($opt, t_sub)), # this is not completely correct. only last one is sub
        t_idx(-1, t_sub)           # expect last one as function
    ),
    $opt
);

sig('Option::map',         $opt, t_sub,                   $opt);
sig('Option::map2',        $opt, $opt,             t_sub, $opt);
sig('Option::map3',        $opt, $opt, $opt,       t_sub, $opt);
sig('Option::map4',        $opt, $opt, $opt, $opt, t_sub, $opt);
sigt('Option::map_v',
    t_array(
        t_of (t_or($opt, t_sub)), # this is not completely correct. only last one is sub
        t_idx(-1, t_sub)           # expect last one as function
    ),
    $opt
);

sig('Option::validate',  $opt, t_sub,       $opt);
sig('Option::check',     $opt, t_sub,       t_bool);
sig('Option::fold',      $opt, $any, t_sub, $any);
sig('Option::fold_back', $opt, $any, t_sub, $any);
sig('Option::iter',      $opt, t_sub,       t_void);
sig('Option::single',    $opt,              t_opt(t_array));
sig('Option::to_array',  $opt,              t_array);
sig('Option::to_seq',    $opt,              t_seq);
# sig('Option::get', ... ) # list context

### Module Functions

# sigt('Option::extract',        t_tuplev($any, ), )  # list context

sigt('Option::dumps',
    t_or(
        t_tuple($opt),
        t_tuple($opt, t_int),
    ),
    t_str
);
sigt('Option::dump',
    t_or(
        t_tuple($opt),
        t_tuple($opt, t_int),
    ),
    t_void
);

1;