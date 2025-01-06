package Sq::Sig::Fs;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $path  = t_or(t_str, t_isa('Path::Tiny'));
my $paths = t_array(t_of $path);
my $pint  = t_int(t_positive);

sigt('Sq::Fs::read_text',     t_tuplev(t_any, $paths),              t_seq);
sigt('Sq::Fs::read_text_gz',  t_tuplev(t_any, $paths),              t_seq);
sigt('Sq::Fs::read_raw',      t_tuplev(t_any, $pint, $paths),       t_seq);
sig ('Sq::Fs::read_bytes',    t_any, $path, t_int,  t_result(t_str,t_str));
sig ('Sq::Fs::compare_text',  t_any, $path, $path,                 t_bool);
sigt('Sq::Fs::recurse',       t_tuplev(t_any, t_array(t_of $path)), t_seq);
sigt('Sq::Fs::children',      t_tuplev(t_any, t_array(t_of $path)), t_seq);

1;