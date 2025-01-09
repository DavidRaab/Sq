package Sq::Sig::Result;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

# Prototype
# sig('Result::Ok')
# sig('Result::Err')

my $any    = t_any;
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
my $matches = t_keys(
    Ok  => t_sub,
    Err => t_sub,
);
sigt('Result::match',    t_tuplev($result, t_as_hash($matches)), $any);
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