package Sq::Sig::Hash;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

### CONSTRUCTORS

sig ('Hash::empty', t_any,                                  t_hash);
sigt('Hash::new',   t_tuplev(t_any, t_array(t_even_sized)), t_hash);
sig ('Hash::bless', t_any, t_hash,                          t_hash);

1;