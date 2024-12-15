package Sq::Sig::Array;
use 5.036;
use Sq::Type;
use Sq::Signature;

sig('Array::empty',      t_any, t_array);
sig('Array::replicate',  t_any, t_int, t_any, t_array);
#sig('Array::new',       t_any, ... );
#sig('Array::wrap',      t_any, ... );
sig('Array::bless',      t_any, t_array, t_array);
sig('Array::from_array', t_any, t_array, t_array);
#sig('Array::concat',     t_any, ...);
sig('Array::init',       t_any, t_int, t_sub, t_array);

1;