package Sq::Sig::Math;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $int  = t_int;
my $str  = t_str;
my $bool = t_bool;

sig('Sq::Math::is_prime',         $int,               $bool);
sig('Sq::Math::fac',              $int,                $int);
sig('Sq::Math::permute_count_up', t_array(t_of $int), $bool);
sig('Sq::Math::to_num_system',    $str, $int,          $str);
sig('Sq::Math::to_binary',        $int,                $str);
sig('Sq::Math::to_hex',           $int,                $str);

1;