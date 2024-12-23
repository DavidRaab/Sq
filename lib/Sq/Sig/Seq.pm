package Sq::Sig::Seq;
use 5.036;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $aos  = t_array(t_of t_seq);
my $hoa  = t_hash (t_of t_array);
my $aoa  = t_array(t_of t_array);

### CONSTRUCTORS

sig ('Seq::from_sub',   t_any, t_sub,               t_seq);
sig ('Seq::always',     t_any, t_any,               t_seq);
sig ('Seq::empty',      t_any,                      t_seq);
sig ('Seq::replicate',  t_any, t_int, t_any,        t_seq);
sig ('Seq::unfold',     t_any, t_any, t_sub,        t_seq);
sig ('Seq::init',       t_any, t_int, t_sub,        t_seq);
sig ('Seq::range_step', t_any, t_num, t_num, t_num, t_seq);
sigt('Seq::new',        t_tuplev(t_any, t_array),   t_seq);
sigt('Seq::wrap',       t_tuplev(t_any, t_array),   t_seq);
sig ('Seq::range',      t_any, t_int, t_int,        t_seq);
sig ('Seq::from_array', t_any, t_array,             t_seq);
sig ('Seq::from_hash',  t_any, t_hash, t_sub,       t_seq);
sigt('Seq::concat',     t_tuplev(t_any, $aos),      t_seq);

### METHODS

sig('Seq::copy',          t_seq,               t_seq);
sig('Seq::append',        t_seq, t_seq,        t_seq);
sig('Seq::map',           t_seq, t_sub,        t_seq);
sig('Seq::map2',          t_seq, t_seq, t_sub, t_seq);
sig('Seq::bind',          t_seq, t_sub,        t_seq);
sig('Seq::flatten',       t_seq,               t_seq);
sig('Seq::flatten_array', t_seq,               t_seq);
sig('Seq::cartesian',     t_seq, t_seq,        t_seq);
sig('Seq::left_join',     t_seq, t_seq, t_sub, t_seq);
sig('Seq::merge',         t_seq, t_sub,        t_seq);
sig('Seq::select',        t_seq, t_any, t_any, t_seq);
sig('Seq::choose',        t_seq, t_sub,        t_seq);
sig('Seq::mapi',          t_seq, t_sub,        t_seq);
sig('Seq::filter',        t_seq, t_sub,        t_seq);
sig('Seq::take',          t_seq, t_int,        t_seq);
sig('Seq::take_while',    t_seq, t_sub,        t_seq);
sig('Seq::skip',          t_seq, t_int,        t_seq);
sig('Seq::skip_while',    t_seq, t_sub,        t_seq);
sig('Seq::indexed',       t_seq,               t_seq);
sig('Seq::distinct_by',   t_seq, t_sub,        t_seq);
sig('Seq::distinct',      t_seq,               t_seq);
sig('Seq::fsts',          t_seq,               t_seq);
sig('Seq::snds',          t_seq,               t_seq);
sig('Seq::zip',           t_seq, t_seq,        t_seq);
sig('Seq::rev',           t_seq,               t_seq);
sig('Seq::sort',          t_seq, t_sub,        t_seq);
sig('Seq::sort_by',       t_seq, t_sub, t_sub, t_seq);
sig('Seq::cache',         t_seq,               t_seq);
sig('Seq::regex_match',   t_seq, t_regex,      t_seq);
sig('Seq::windowed',      t_seq, t_int,        t_seq);
sig('Seq::intersperse',   t_seq, t_any,        t_seq);
sig('Seq::infinity',      t_seq,               t_seq);
sig('Seq::repeat',        t_seq, t_int,        t_seq);



# sig('Seq::sort_num',      $anum,                 t_seq);
# sig('Seq::sort_str',      $astr,                 t_seq);
# sig('Seq::sort_hash_str', $aoh,    t_str,        $aoh);
# sigt('Seq::slice',             t_tuplev(t_seq, $aint), t_seq);
# sig ('Seq::extract',           t_seq, t_int, t_int,    t_seq);


### SIDE-EFFECTS

sig('Seq::iter',     t_seq, t_sub, t_void);
sig('Seq::iteri',    t_seq, t_sub, t_void);
sig('Seq::foreachi', t_seq, t_sub, t_void);
sig('Seq::foreachi', t_seq, t_sub, t_void);
sig('Seq::do',       t_seq, t_sub,  t_seq);
sig('Seq::doi',      t_seq, t_sub,  t_seq);

### CONVERTER
sig('Seq::group_fold', t_seq, t_sub, t_sub, t_sub,  t_hash);
sig('Seq::group_by',   t_seq, t_sub,                $hoa);
sig('Seq::fold',       t_seq, t_any, t_sub,         t_any);
sig('Seq::fold_mut',   t_seq, t_any, t_sub,         t_any);
sig('Seq::reduce',     t_seq, t_sub,                t_opt);
sig('Seq::first',      t_seq,                       t_opt);
sig('Seq::last',       t_seq,                       t_opt);
sigt('Seq::to_array',
    t_or(
        t_tuple(t_seq),
        t_tuple(t_seq, t_int),
    ),
    t_array
);
sig('Seq::to_seq',     t_seq, t_seq);
#sig('Seq::expand',    t_seq, ...);
sig('Seq::length',     t_seq,                       t_int);
sig('Seq::sum',        t_seq,                       t_num);
sig('Seq::sum_by',     t_seq, t_sub,                t_num);
sig('Seq::min',        t_seq,                       t_opt(t_num));
sig('Seq::min_by',     t_seq, t_sub,                t_opt);
sig('Seq::min_str',    t_seq,                       t_opt(t_str));
sig('Seq::min_str_by', t_seq, t_sub,                t_opt);
sig('Seq::max',        t_seq,                       t_opt(t_num));
sig('Seq::max_by',     t_seq, t_sub,                t_opt);
sig('Seq::max_str',    t_seq,                       t_opt(t_str));
sig('Seq::max_str_by', t_seq, t_sub,                t_opt);
sig('Seq::join',       t_seq, t_str,                t_str);
sig('Seq::split',      t_seq, t_or(t_regex, t_str), t_seq);
sig('Seq::as_hash',    t_seq,                       t_hash);
sig('Seq::to_hash',    t_seq, t_sub,                t_hash);
sig('Seq::to_hash_of_array',  t_seq, t_sub,         $hoa);
sig('Seq::to_array_of_array', t_seq,                $aoa);
sig('Seq::find',       t_seq, t_sub,                t_opt);
sig('Seq::any',        t_seq, t_sub,                t_bool);
sig('Seq::all',        t_seq, t_sub,                t_bool);
sig('Seq::none',       t_seq, t_sub,                t_bool);
sig('Seq::pick',       t_seq, t_sub,                t_opt);
sigt('Seq::dump',
    t_or(
        t_tuple(t_seq),
        t_tuple(t_seq, t_int),
        t_tuple(t_seq, t_int, t_int),
    ),
    t_str
);
sigt('Seq::dumpw',
    t_or(
        t_tuple(t_seq),
        t_tuple(t_seq, t_int),
        t_tuple(t_seq, t_int, t_int),
    ),
    t_void
);
sig('Seq::equal', t_seq, t_any, t_any);


# sig('Seq::keyed_by',   t_seq, t_sub,                t_hash);
# sig('Seq::count',      t_seq,                       t_hash(t_of t_int));
# sig('Seq::count_by',   t_seq, t_sub,                t_hash(t_of t_int));

1;