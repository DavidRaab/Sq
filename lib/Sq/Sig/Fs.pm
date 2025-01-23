package Sq::Sig::Fs;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $path   = t_or(t_str, t_isa('Path::Tiny'));
my $paths  = t_array(t_of $path);
my $pint   = t_int(t_positive);
my $sha512 = t_match(qr/\A[0-9a-f]{128}\z/);

sigt('Sq::Fs::read_text',     $paths,                  t_seq);
sig ('Sq::Fs::write_text',    $path, t_any,            t_result(t_int, t_hash));
sigt('Sq::Fs::read_text_gz',  $paths,                  t_seq);
sigt('Sq::Fs::read_raw',      t_tuplev($pint, $paths), t_seq);
sigt('Sq::Fs::read_bytes',    t_tuplev(t_int, $paths), t_result(t_str,t_str));
sig ('Sq::Fs::compare_text',  $path, $path,            t_bool);
sigt('Sq::Fs::recurse',       t_array(t_of $path),     t_seq);
sigt('Sq::Fs::children',      t_array(t_of $path),     t_seq);
sigt('Sq::Fs::sha512',        $paths,                  t_result($sha512, t_str));
sig ('Sq::Fs::make_link',     $path, $path,            t_void);

1;