package Sq::Sig::Array;
use 5.036;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $aoa   = t_array(t_all t_array);
my $aoh   = t_array(t_all t_hash);
my $hoa   = t_hash (t_all t_array);

my $aint = t_array(t_all t_int);
my $anum = t_array(t_all t_num);
my $astr = t_array(t_all t_str);

### CONSTRUCTORS

sigt('Array::new',        t_tuplev(t_any, t_array), t_array);
sigt('Array::wrap',       t_tuplev(t_any, t_array), t_array);
sigt('Array::concat',     t_tuplev(t_any, $aoa),    t_array);
sig ('Array::empty',      t_any,               t_array);
sig ('Array::replicate',  t_any, t_int, t_any, t_array);
sig ('Array::bless',      t_any, t_array,      t_array);
sig ('Array::from_array', t_any, t_array,      t_array);
sig ('Array::init',       t_any, t_int, t_sub, t_array);

# Second argument is 'State, would be good to back-reference the type
sig('Array::unfold',     t_any, t_any, t_sub, t_array);
sig('Array::range_step', t_any, t_num, t_num, t_num, t_array);
sig('Array::range',      t_any, t_int, t_int, t_array);

### METHODS

sig('Array::copy',          t_array,               t_array);
sig('Array::bind',          t_array, t_sub,        t_array);
sig('Array::flatten',       $aoa,                  t_array);
sig('Array::cartesian',     t_array, t_array,      t_array(t_all t_tuple(t_any, t_any)));
sig('Array::append',        t_array, t_array,      t_array);
sig('Array::rev',           t_array,               t_array);
sig('Array::map',           t_array, t_sub,        t_array);
sig('Array::map_e',         t_array, t_str,        t_array);
sig('Array::choose',        t_array, t_sub,        t_array);
sig('Array::mapi',          t_array, t_sub,        t_array);
sig('Array::filter',        t_array, t_sub,        t_array);
sig('Array::filter_e',      t_array, t_str,        t_array);
sig('Array::skip',          t_array, t_int,        t_array);
sig('Array::take',          t_array, t_int,        t_array);
sig('Array::indexed',       t_array,               t_array(t_all t_tuple(t_any, t_int)));
sig('Array::zip',           t_array, t_array,      t_array(t_all t_tuple(t_any, t_any)));
sig('Array::sort',          t_array, t_sub,        t_array);
sig('Array::sort_by',       t_array, t_sub, t_sub, t_array);
sig('Array::sort_num',      $anum,                 t_array);
sig('Array::sort_str',      $astr,                 t_array);
sig('Array::sort_hash_str', $aoh,    t_str,        $aoh);
sig('Array::fsts',          $aoa,                  t_array);
sig('Array::snds',          $aoa,                  t_array);
sigt('Array::to_array',
    t_or(
        t_tuple(t_array),
        t_tuple(t_array, t_int),
    ),
    t_array
);
sig ('Array::to_array_of_array', $aoa,                     $aoa);
sig ('Array::distinct',          t_array,                  t_array);
sig ('Array::distinct_by',       t_array, t_sub,           t_array);
sig ('Array::regex_match',       $astr,   t_regex,         t_array(t_all $astr));
sig ('Array::windowed',          t_array, t_int,           $aoa);
sig ('Array::intersperse',       t_array, t_any,           t_array);
sig ('Array::repeat',            t_array, t_int,           t_array);
sig ('Array::take_while',        t_array, t_sub,           t_array);
sig ('Array::skip_while',        t_array, t_sub,           t_array);
sigt('Array::slice',             t_tuplev(t_array, $aint), t_array);
sig ('Array::extract',           t_array, t_int, t_int,    t_array);

### SIDE-EFFECTS

sig('Array::iter',     t_array, t_sub, t_void);
sig('Array::iteri',    t_array, t_sub, t_void);
sig('Array::foreachi', t_array, t_sub, t_void);
sig('Array::foreachi', t_array, t_sub, t_void);

### CONVERTER

sig('Array::fold',       t_array, t_any, t_sub,         t_any);
sig('Array::fold_mut',   t_array, t_any, t_sub,         t_any);
sig('Array::reduce',     t_array, t_sub,                t_opt(t_any));
sig('Array::length',     t_array,                       t_int);
#sig('Array::expand',   t_array, ...);
sig('Array::first',      t_array,                       t_opt(t_any));
sig('Array::last',       t_array,                       t_opt(t_any));
sig('Array::sum',        $anum,                         t_num);
sig('Array::sum_by',     t_array, t_sub,                t_num);
sig('Array::join',       $astr, t_str,                  t_str);
sig('Array::split',      t_array, t_or(t_regex, t_str), t_array(t_all $astr));
sig('Array::min',        $astr,                         t_opt(t_num));
sig('Array::min_by',     t_array, t_sub,                t_opt);
sig('Array::min_str',    $astr,                         t_opt(t_str));
sig('Array::min_str_by', t_array, t_sub,                t_opt);
sig('Array::max',        $anum,                         t_opt(t_num));
sig('Array::max_by',     t_array, t_sub,                t_opt);
sig('Array::max_str',    $astr,                         t_opt(t_str));
sig('Array::max_str_by', t_array, t_sub,                t_opt);
sig('Array::group_fold', t_array, t_sub, t_sub, t_sub,  t_hash);
sig('Array::to_hash',    t_array, t_sub,                t_hash);
sig('Array::to_hash_of_array', t_array, t_sub,          $hoa);
sig('Array::as_hash',    t_even_sized,                  t_hash);
sig('Array::keyed_by',   t_array, t_sub,                t_hash);
sig('Array::group_by',   t_array, t_sub,                $hoa);
sig('Array::count',      t_array,                       t_hash(t_all t_int));
sig('Array::count_by',   t_array, t_sub,                t_hash(t_all t_int));
sig('Array::find',       t_array, t_sub,                t_opt);
sig('Array::any',        t_array, t_sub,                t_bool);
sig('Array::all',        t_array, t_sub,                t_bool);
sig('Array::none',       t_array, t_sub,                t_bool);
sig('Array::pick',       t_array, t_sub,                t_opt);
sig('Array::to_seq',     t_array,                       t_seq);
sigt('Array::dump',
    t_or(
        t_tuple(t_array),
        t_tuple(t_array, t_int),
        t_tuple(t_array, t_int, t_int),
    ),
    t_void
);
sigt('Array::dumpw',
    t_or(
        t_tuple(t_array),
        t_tuple(t_array, t_int),
        t_tuple(t_array, t_int, t_int),
    ),
    t_void
);

### MUTATION

sigt('Array::push',     t_tuplev(t_array, t_array), t_void);
sig ('Array::pop',      t_array, t_any);
sig ('Array::shift',    t_array, t_any);
sigt('Array::unshift',  t_tuplev(t_array, t_array), t_void);
sig ('Array::blit',     t_array, t_int, t_array, t_int, t_int, t_void);
sig ('Array::shuffle',  t_array, t_void);

1;