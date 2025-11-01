package Sq::Sig::Str;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $pint = t_int(t_min 1);

sig('Sq::Core::Str::escape_html', t_str, t_str);
sig('Sq::Core::Str::chunk',       t_str, $pint, t_array);

1;