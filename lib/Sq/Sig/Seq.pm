package Sq::Sig::Seq;
use 5.036;
use Sq::Type;
use Sq::Signature;

### TODO -- Currently just a copy from Array. Just replaced Array:: with Seq:: at the moment

# Some predefined types
my $aoa  = t_array(t_of t_array);
my $aoh  = t_array(t_of t_hash);
my $hoa  = t_hash (t_of t_array);
my $aint = t_array(t_of t_int);
my $anum = t_array(t_of t_num);
my $astr = t_array(t_of t_str);

### CONSTRUCTORS

sigt('Seq::new',        t_tuplev(t_any, t_array),   t_array);
sigt('Seq::wrap',       t_tuplev(t_any, t_array),   t_array);
sigt('Seq::concat',     t_tuplev(t_any, $aoa),      t_array);
sig ('Seq::empty',      t_any,                      t_array);
sig ('Seq::replicate',  t_any, t_int, t_any,        t_array);
sig ('Seq::bless',      t_any, t_array,             t_array);
sig ('Seq::from_array', t_any, t_array,             t_array);
sig ('Seq::init',       t_any, t_int, t_sub,        t_array);
# Second argument is 'State, would be good to back-reference the type
sig ('Seq::unfold',     t_any, t_any, t_sub,        t_array);
sig ('Seq::range_step', t_any, t_num, t_num, t_num, t_array);
sig ('Seq::range',      t_any, t_int, t_int,        t_array);


### METHODS

sig('Seq::copy',          t_array,               t_array);
sig('Seq::bind',          t_array, t_sub,        t_array);
sig('Seq::flatten',       $aoa,                  t_array);
sig('Seq::cartesian',     t_array, t_array,      t_array(t_of t_tuple(t_any, t_any)));
sig('Seq::append',        t_array, t_array,      t_array);
sig('Seq::rev',           t_array,               t_array);
sig('Seq::map',           t_array, t_sub,        t_array);
sig('Seq::map_e',         t_array, t_str,        t_array);
sig('Seq::choose',        t_array, t_sub,        t_array);
sig('Seq::mapi',          t_array, t_sub,        t_array);
sig('Seq::filter',        t_array, t_sub,        t_array);
sig('Seq::filter_e',      t_array, t_str,        t_array);
sig('Seq::skip',          t_array, t_int,        t_array);
sig('Seq::take',          t_array, t_int,        t_array);
sig('Seq::indexed',       t_array,               t_array(t_of t_tuple(t_any, t_int)));
sig('Seq::zip',           t_array, t_array,      t_array(t_of t_tuple(t_any, t_any)));
sig('Seq::sort',          t_array, t_sub,        t_array);
sig('Seq::sort_by',       t_array, t_sub, t_sub, t_array);
sig('Seq::sort_num',      $anum,                 t_array);
sig('Seq::sort_str',      $astr,                 t_array);
sig('Seq::sort_hash_str', $aoh,    t_str,        $aoh);
sig('Seq::fsts',          $aoa,                  t_array);
sig('Seq::snds',          $aoa,                  t_array);
sigt('Seq::to_array',
    t_or(
        t_tuple(t_array),
        t_tuple(t_array, t_int),
    ),
    t_array
);
sig ('Seq::to_array_of_array', $aoa,                     $aoa);
sig ('Seq::distinct',          t_array,                  t_array);
sig ('Seq::distinct_by',       t_array, t_sub,           t_array);
sig ('Seq::regex_match',       $astr,   t_regex,         t_array(t_of $astr));
sig ('Seq::windowed',          t_array, t_int,           $aoa);
sig ('Seq::intersperse',       t_array, t_any,           t_array);
sig ('Seq::repeat',            t_array, t_int,           t_array);
sig ('Seq::take_while',        t_array, t_sub,           t_array);
sig ('Seq::skip_while',        t_array, t_sub,           t_array);
sigt('Seq::slice',             t_tuplev(t_array, $aint), t_array);
sig ('Seq::extract',           t_array, t_int, t_int,    t_array);


### SIDE-EFFECTS

sig('Seq::iter',     t_array, t_sub, t_void);
sig('Seq::iteri',    t_array, t_sub, t_void);
sig('Seq::foreachi', t_array, t_sub, t_void);
sig('Seq::foreachi', t_array, t_sub, t_void);


### CONVERTER

sig('Seq::fold',       t_array, t_any, t_sub,         t_any);
sig('Seq::fold_mut',   t_array, t_any, t_sub,         t_any);
sig('Seq::reduce',     t_array, t_sub,                t_opt(t_any));
sig('Seq::length',     t_array,                       t_int);
#sig('Seq::expand',   t_array, ...);
sig('Seq::first',      t_array,                       t_opt(t_any));
sig('Seq::last',       t_array,                       t_opt(t_any));
sig('Seq::sum',        $anum,                         t_num);
sig('Seq::sum_by',     t_array, t_sub,                t_num);
sig('Seq::join',       $astr, t_str,                  t_str);
sig('Seq::split',      t_array, t_or(t_regex, t_str), t_array(t_of $astr));
sig('Seq::min',        $astr,                         t_opt(t_num));
sig('Seq::min_by',     t_array, t_sub,                t_opt);
sig('Seq::min_str',    $astr,                         t_opt(t_str));
sig('Seq::min_str_by', t_array, t_sub,                t_opt);
sig('Seq::max',        $anum,                         t_opt(t_num));
sig('Seq::max_by',     t_array, t_sub,                t_opt);
sig('Seq::max_str',    $astr,                         t_opt(t_str));
sig('Seq::max_str_by', t_array, t_sub,                t_opt);
sig('Seq::group_fold', t_array, t_sub, t_sub, t_sub,  t_hash);
sig('Seq::to_hash',    t_array, t_sub,                t_hash);
sig('Seq::to_hash_of_array', t_array, t_sub,          $hoa);
sig('Seq::as_hash',    t_even_sized,                  t_hash);
sig('Seq::keyed_by',   t_array, t_sub,                t_hash);
sig('Seq::group_by',   t_array, t_sub,                $hoa);
sig('Seq::count',      t_array,                       t_hash(t_of t_int));
sig('Seq::count_by',   t_array, t_sub,                t_hash(t_of t_int));
sig('Seq::find',       t_array, t_sub,                t_opt);
sig('Seq::any',        t_array, t_sub,                t_bool);
sig('Seq::all',        t_array, t_sub,                t_bool);
sig('Seq::none',       t_array, t_sub,                t_bool);
sig('Seq::pick',       t_array, t_sub,                t_opt);
sig('Seq::to_seq',     t_array,                       t_seq);
sigt('Seq::dump',
    t_or(
        t_tuple(t_array),
        t_tuple(t_array, t_int),
        t_tuple(t_array, t_int, t_int),
    ),
    t_str
);
sigt('Seq::dumpw',
    t_or(
        t_tuple(t_array),
        t_tuple(t_array, t_int),
        t_tuple(t_array, t_int, t_int),
    ),
    t_void
);


### MUTATION

sigt('Seq::push',     t_tuplev(t_array, t_array), t_void);
sig ('Seq::pop',      t_array, t_any);
sig ('Seq::shift',    t_array, t_any);
sigt('Seq::unshift',  t_tuplev(t_array, t_array), t_void);
sig ('Seq::blit',     t_array, t_int, t_array, t_int, t_int, t_void);
sig ('Seq::shuffle',  t_array, t_void);

1;