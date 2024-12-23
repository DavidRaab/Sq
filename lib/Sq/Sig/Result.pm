package Sq::Sig::Result;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

# Prototype
# sig('Result::Ok')
# sig('Result::Err')

sig('Result::map',          t_result,                               t_sub, t_result);
sig('Result::map2',         t_result, t_result,                     t_sub, t_result);
sig('Result::map3',         t_result, t_result, t_result,           t_sub, t_result);
sig('Result::map4',         t_result, t_result, t_result, t_result, t_sub, t_result);
sig('Result::mapErr',       t_result,                               t_sub, t_result);
sig('Result::or_else',      t_result, t_result,                            t_result);
sig('Result::or_else_with', t_result, t_sub,                               t_result);

### SIDE-EFFECTS

sig('Result::iter',      t_result, t_sub, t_void);

### CONVERTERS
my $matches = t_hash(t_keys(
    Ok  => t_sub,
    Err => t_sub,
));
sigt('Result::match',    t_tuplev(t_result, t_as_hash($matches)), t_any);
sig('Result::fold',      t_result, t_any, t_sub,                  t_any);
sig('Result::is_ok',     t_any,                                  t_bool);
sig('Result::is_err',    t_any,                                  t_bool);
sig('Result::or',        t_result, t_any,                         t_any);
sig('Result::or_with',   t_result, t_sub,                         t_any);
sig('Result::to_option', t_result,                                t_opt);
sig('Result::to_array',  t_result,                              t_array);
sig('Result::value',     t_result,                                t_any);
sig('Result::get',       t_result,                                t_any);

### MODULE FUNCTIONS

sig('Result::is_result', t_any, t_any, t_bool);

1;