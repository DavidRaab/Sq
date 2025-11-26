package Sq::Sig::Math;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $aint = t_array(t_of t_int);

sig('Sq::Math::is_prime',           t_int,        t_bool);
sig('Sq::Math::fac',                t_int,         t_int);
sig('Sq::Math::permute_count_up',   $aint,        t_bool);
sig('Sq::Math::to_num_system',      t_str, t_int,  t_str);
sig('Sq::Math::to_binary',          t_int,         t_str);
sig('Sq::Math::to_hex',             t_int,         t_str);
sig('Sq::Math::divide_even_spread', t_int, t_int,  $aint);

1;