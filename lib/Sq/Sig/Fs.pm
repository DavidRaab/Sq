package Sq::Sig::Fs;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $str    = t_str;
my $int    = t_int;
my $path   = t_or($str, t_isa('Path::Tiny'));
my $paths  = t_array(t_of $path);
my $pint   = t_int(t_positive);
my $sha512 = t_match(qr/\A[0-9a-f]{128}\z/);
my $seq    = t_seq;

sigt('Sq::Fs::read_text',     $paths,                  $seq);
sig ('Sq::Fs::write_text',    $path, t_any,            t_result($int, t_hash));
sigt('Sq::Fs::read_text_gz',  $paths,                  $seq);
sigt('Sq::Fs::read_raw',      t_tuplev($pint, $paths), $seq);
sigt('Sq::Fs::read_bytes',    t_tuplev($int, $paths), t_result($str,$str));
sig ('Sq::Fs::compare_text',  $path, $path,          t_bool);
sigt('Sq::Fs::recurse',       $paths,                  $seq);
sigt('Sq::Fs::children',      $paths,                  $seq);
sigt('Sq::Fs::sha512',        $paths,                t_result($sha512, $str));
sig ('Sq::Fs::make_link',     $path, $path,          t_void);

1;