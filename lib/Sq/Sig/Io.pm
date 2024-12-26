package Sq::Sig::Io;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $path = t_or(t_str, t_isa('Path::Tiny'));

sig ('Sq::Io::open_text', t_any, $path, t_seq);
sigt('Sq::Io::recurse',   t_tuplev(t_any, t_array(t_of $path)), t_seq);
sigt('Sq::Io::children',  t_tuplev(t_any, t_array(t_of $path)), t_seq);

1;