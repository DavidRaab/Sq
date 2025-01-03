package Sq::Sig::Fmt;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $table_input = t_hash(t_keys(
    data => t_array(t_of(t_array(t_of t_str))),
));

sig('Sq::Fmt::table', t_any, $table_input, t_void);

1;