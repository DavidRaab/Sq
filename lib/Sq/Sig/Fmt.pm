package Sq::Sig::Fmt;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $table_input = t_keys(
    data => t_array(t_of(t_array(t_of t_str))),
);

sig('Sq::Fmt::table', $table_input, t_void);
sig('Sq::Fmt::html',  t_any,        t_tuple(t_eq('HTML'), t_str));

1;