package Sq::Sig::Math;
use 5.036;
use Sq::Type;
use Sq::Signature;

sig('Sq::Math::is_prime',         t_int,               t_bool);
sig('Sq::Math::fac',              t_int,               t_int);
sig('Sq::Math::permute_count_up', t_array(t_of t_int), t_bool);

1;