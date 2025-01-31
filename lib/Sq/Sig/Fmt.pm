package Sq::Sig::Fmt;
use 5.036;
use Sq::Type;
use Sq::Signature;

# Fmt::Table uses with_dispatch() so here we just use t_any
sig('Sq::Fmt::table', t_any, t_void);
sig('Sq::Fmt::html',  t_any, t_tuple(t_eq('HTML'), t_str));

1;