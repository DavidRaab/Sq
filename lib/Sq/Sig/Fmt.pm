package Sq::Sig::Fmt;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $any   = t_any;
my $array = t_array;

# Fmt::Table uses with_dispatch() so here we just use t_any
sig('Sq::Fmt::table',       $any,   t_void);
sig('Sq::Fmt::html',        $any,   t_tuple(t_eq('HTML'), t_str));
sig('Sq::Fmt::nl_to_array', $array, $array);

1;