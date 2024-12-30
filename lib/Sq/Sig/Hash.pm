package Sq::Sig::Hash;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $kv = t_tuple(t_str, t_any);

### CONSTRUCTORS

sig ('Hash::empty',      t_any,                                  t_hash);
sigt('Hash::new',        t_tuplev(t_any, t_array(t_even_sized)), t_hash);
sig ('Hash::bless',      t_any, t_hash,                          t_hash);
sig ('Hash::locked',     t_any, t_hash,                          t_hash);
sig ('Hash::init',       t_any, t_int, t_sub,                    t_hash);
sig ('Hash::from_array', t_any, t_array, t_sub,                  t_hash);

### METHODS

sig ('Hash::keys',         t_hash,                t_array(t_of t_str));
sig ('Hash::values',       t_hash,                t_array);
sig ('Hash::map',          t_hash, t_sub,         t_hash);
sig ('Hash::find',         t_hash, t_sub,         t_opt($kv));
sig ('Hash::pick',         t_hash, t_sub,         t_opt);
sig ('Hash::filter',       t_hash, t_sub,         t_hash);
sig ('Hash::fold',         t_hash, t_any, t_sub,  t_any);
sig ('Hash::length',       t_hash,                t_int);
sig ('Hash::is_empty',     t_hash,                t_bool);
sig ('Hash::bind',         t_hash, t_sub,         t_hash);
sig ('Hash::append',       t_hash, t_hash,        t_hash);
sig ('Hash::union',        t_hash, t_hash, t_sub, t_hash);
sig ('Hash::intersection', t_hash, t_hash, t_sub, t_hash);
sig ('Hash::diff',         t_hash, t_hash,        t_hash);
sigt('Hash::concat',       t_tuplev(t_hash, t_array(t_of t_hash)), t_hash);
sig ('Hash::is_subset_of', t_hash, t_hash,        t_int);
sig ('Hash::get',          t_hash, t_str,         t_opt);
sig ('Hash::copy',         t_hash,                t_hash);
sigt('Hash::extract',      t_tuplev(t_hash, t_array(t_min(1), t_of t_str)), t_array(t_of t_opt));
sigt('Hash::slice',        t_tuplev(t_hash, t_array(t_min(1), t_of t_str)), t_hash);
sigt('Hash::with',         t_tuplev(t_hash, t_array(t_even_sized)),         t_hash); # can be improved
sigt('Hash::withf',        t_tuplev(t_hash, t_array(t_even_sized)),         t_hash); # can be improved
sigt('Hash::has_keys',     t_tuplev(t_hash, t_array(t_of t_str)),           t_bool);
sig ('Hash::equal',        t_hash, t_any,                                   t_bool);
sig ('Hash::to_array',     t_hash, t_sub,                                   t_array);

### SIDE-EFFECTS

sigt('Hash::on',      t_tuplev(t_hash, t_array(t_even_sized)), t_void);
sig ('Hash::iter',    t_hash, t_sub,                           t_void);
sigt('Hash::lock',    t_tuplev(t_hash, t_array(t_of t_str)),   t_hash);

### MUTATION METHODS

sigt('Hash::set',     t_tuplev(t_hash, t_array(t_even_sized)),         t_void);
sigt('Hash::change',  t_tuplev(t_hash, t_array(t_even_sized)),         t_void);
sigt('Hash::push',    t_tuplev(t_hash, t_str, t_array(t_min 1)),       t_void);
sigt('Hash::delete',  t_tuplev(t_hash, t_array(t_min(1), t_of t_str)), t_void);

sigt('Hash::dump',
    t_or(
        t_tuple(t_hash),
        t_tuple(t_hash, t_int),
        t_tuple(t_hash, t_int, t_int),
    ),
    t_str
);

sigt('Hash::dumpw',
    t_or(
        t_tuple(t_hash),
        t_tuple(t_hash, t_int),
        t_tuple(t_hash, t_int, t_int),
    ),
    t_void
);

1;