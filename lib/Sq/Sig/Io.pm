package Sq::Sig::Io;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $path = t_or(t_str, t_ref('Path::Tiny'));

sig('Sq::Io::youtube',  t_str, t_result);
sig('Sq::Io::csv_read', $path,    t_seq);

1;
