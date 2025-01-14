package Sq::Sig::Hash;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $any  = t_any();
my $kv   = t_tuple(t_str, $any);
my $hash = t_hash();
my $sub  = t_sub();
my $int  = t_int();

### CONSTRUCTORS

sig ('Hash::empty',      $any,                                  $hash);
sigt('Hash::new',        t_tuplev($any, t_array(t_even_sized)), $hash);
sig ('Hash::bless',      $any, $hash,                           $hash);
sig ('Hash::locked',     $any, $hash,                           $hash);
sig ('Hash::init',       $any, $int, $sub,                    $hash);
sig ('Hash::from_array', $any, t_array, $sub,                  $hash);

### METHODS

sig ('Hash::keys',         $hash,                t_array(t_of t_str));
sig ('Hash::values',       $hash,                t_array);
sig ('Hash::map',          $hash, $sub,          $hash);
sig ('Hash::find',         $hash, $sub,          t_opt($kv));
sig ('Hash::pick',         $hash, $sub,          t_opt);
sig ('Hash::keep',         $hash, $sub,          $hash);
sig ('Hash::fold',         $hash, $any, $sub,    $any);
sig ('Hash::fold_back',    $hash, $any, $sub,    $any);
sig ('Hash::length',       $hash,                $int);
sig ('Hash::is_empty',     $hash,                t_bool);
sig ('Hash::bind',         $hash, $sub,          $hash);
sig ('Hash::append',       $hash, $hash,         $hash);
sig ('Hash::union',        $hash, $hash, $sub,   $hash);
sig ('Hash::intersect',    $hash, $hash, $sub,   $hash);
sig ('Hash::diff',         $hash, $hash,         $hash);
sigt('Hash::concat',       t_tuplev($hash, t_array(t_of $hash)), $hash);
sig ('Hash::is_subset_of', $hash, $hash,         $int);
sig ('Hash::get',          $hash, t_str,         t_opt);
sig ('Hash::copy',         $hash,                $hash);
sigt('Hash::extract',      t_tuplev($hash, t_array(t_min(1), t_of t_str)), t_array(t_of t_opt));
sigt('Hash::slice',        t_tuplev($hash, t_array(t_min(1), t_of t_str)), $hash);
sigt('Hash::with',         t_tuplev($hash, t_array(t_even_sized)),         $hash); # can be improved
sigt('Hash::withf',        t_tuplev($hash, t_array(t_even_sized)),         $hash); # can be improved
sigt('Hash::has_keys',     t_tuplev($hash, t_array(t_of t_str)),           t_bool);
sig ('Hash::equal',        $hash, $any,                                    t_bool);
sig ('Hash::to_array',     $hash, $sub,                                    t_array);

### SIDE-EFFECTS

sigt('Hash::on',        t_tuplev($hash, t_array(t_even_sized)), t_void);
sig ('Hash::iter',      $hash, $sub,                            t_void);
sig ('Hash::iter_sort', $hash, $sub, $sub,                      t_void);
sigt('Hash::lock',      t_tuplev($hash, t_array(t_of t_str)),   $hash);

### MUTATION METHODS

sigt('Hash::set',     t_tuplev($hash, t_array(t_even_sized)),         t_void);
sigt('Hash::change',  t_tuplev($hash, t_array(t_even_sized)),         t_void);
sigt('Hash::push',    t_tuplev($hash, t_str, t_array(t_min 1)),       t_void);
sigt('Hash::delete',  t_tuplev($hash, t_array(t_min(1), t_of t_str)), t_void);

1;