package Sq::Sig::Core;
use 5.036;
use Sq::Type;
use Sq::Signature;

### OPTION MODULE

# Some predefined types
my $any  = t_any;
my $opt  = t_opt;
my $aopt = t_array(t_of $opt);


sigt('Option::Some', t_tuplev(t_array), $opt);
# sigt('Option::None', t_tuple(),         $opt); # doesn't work because of Prototype

sig('Option::is_some', $any, t_bool);
sig('Option::is_none', $any, t_bool);

my $omatch = t_keys(
    Some => t_sub,
    None => t_sub,
);
sigt('Option::match', t_tuplev($opt, t_as_hash($omatch)), $any);

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
        t_idx(-1, t_sub)          # expect last one as function
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
        t_idx(-1, t_sub)          # expect last one as function
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


### RESULT MODULE
my $result = t_result;

sig('Result::map',          $result,                            t_sub, $result);
sig('Result::map2',         $result, $result,                   t_sub, $result);
sig('Result::map3',         $result, $result, $result,          t_sub, $result);
sig('Result::map4',         $result, $result, $result, $result, t_sub, $result);
sig('Result::mapErr',       $result,                            t_sub, $result);
sig('Result::or_else',      $result, $result,                          $result);
sig('Result::or_else_with', $result, t_sub,                            $result);

### SIDE-EFFECTS

sig('Result::iter',      $result, t_sub, t_void);

### CONVERTERS
my $rmatch = t_keys(
    Ok  => t_sub,
    Err => t_sub,
);
sigt('Result::match',    t_tuplev($result, t_as_hash($rmatch)), $any);
sig('Result::fold',      $result, $any, t_sub,                   $any);
sig('Result::is_ok',     $any,                                 t_bool);
sig('Result::is_err',    $any,                                 t_bool);
sig('Result::or',        $result, $any,                          $any);
sig('Result::or_with',   $result, t_sub,                         $any);
sig('Result::to_option', $result,                               t_opt);
sig('Result::to_array',  $result,                             t_array);
sig('Result::value',     $result,                                $any);
sig('Result::get',       $result,                                $any);

1;