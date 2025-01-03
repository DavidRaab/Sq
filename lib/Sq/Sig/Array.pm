package Sq::Sig::Array;
use 5.036;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $array = t_array;
my $aoa   = t_array(t_of t_array);
my $aoh   = t_array(t_of t_hash);
my $hoa   = t_hash (t_of t_array);
my $aint  = t_array(t_of t_int);
my $anum  = t_array(t_of t_num);
my $astr  = t_array(t_of t_str);
my $any   = t_any;
my $opt   = t_opt;
my $aopt  = t_array(t_of $opt);
my $sub   = t_sub;

my $pint = t_int(t_positive);

### CONSTRUCTORS

sigt('Array::new',        t_tuplev($any, $array),    $array);
sigt('Array::concat',     t_tuplev($any, $aoa),      $array);
sig ('Array::empty',      $any,                      $array);
sig ('Array::replicate',  $any, t_int, $any,         $array);
sig ('Array::bless',      $any, $array,              $array);
sig ('Array::from_array', $any, $array,              $array);
sig ('Array::init',       $any, t_int, $sub,         $array);
sig ('Array::init2d',     $any, $pint, $pint, $sub,  $array);
# Second argument is 'State, would be good to back-reference the type
sig ('Array::unfold',     $any, $any, $sub,          $array);
sig ('Array::range_step', $any, t_num, t_num, t_num, $array);
sig ('Array::range',      $any, t_int, t_int,        $array);


### METHODS

sig ('Array::copy',          $array,               $array);
sig ('Array::bind',          $array, $sub,         $array);
sig ('Array::flatten',       $aoa,                 $array);
sig ('Array::merge',         $aoa,                 $array);
sig ('Array::cartesian',     $array, $array,       t_array(t_of t_tuple($any, $any)));
sig ('Array::append',        $array, $array,       $array);
sig ('Array::rev',           $array,               $array);
sig ('Array::map',           $array, $sub,         $array);
sig ('Array::map_e',         $array, t_str,        $array);
sig ('Array::choose',        $array, $sub,         $array);
sig ('Array::mapi',          $array, $sub,         $array);
sig ('Array::keep',          $array, $sub,         $array);
sig ('Array::keep_e',        $array, t_str,        $array);
sig ('Array::skip',          $array, t_int,        $array);
sig ('Array::take',          $array, t_int,        $array);
sig ('Array::indexed',       $array,               t_array(t_of t_tuple($any, t_int)));
sigt('Array::zip',          t_array(t_of $array),  t_array(t_of t_array));
sig ('Array::sort',          $array, $sub,         $array);
sig ('Array::sort_by',       $array, $sub, $sub,   $array);
sig ('Array::sort_hash',     $array, $sub, t_str,  $array);
sig ('Array::fsts',          $aoa,                 $array);
sig ('Array::snds',          $aoa,                 $array);
sigt('Array::to_array',
    t_or(
        t_tuple($array),
        t_tuple($array, t_int),
    ),
    $array
);
sig ('Array::to_array_of_array', $aoa,                       $aoa);
sig ('Array::distinct',          $array,                   $array);
sig ('Array::distinct_by',       $array, $sub,             $array);
sig ('Array::rx',                $astr,  t_regex,          t_array(t_of t_str));
sig ('Array::rxm',               $astr,  t_regex,          t_array(t_of $astr));
sig ('Array::rxs',               $astr,  t_regex, t_sub,   t_array(t_of t_str));
sig ('Array::rxsg',              $astr,  t_regex, t_sub,   t_array(t_of t_str));
sig ('Array::chunked',           $array, t_int,              $aoa);
sig ('Array::windowed',          $array, t_int,              $aoa);
sig ('Array::intersperse',       $array, $any,             $array);
sig ('Array::repeat',            $array, t_int,            $array);
sig ('Array::take_while',        $array, $sub,             $array);
sig ('Array::skip_while',        $array, $sub,             $array);
sigt('Array::slice',             t_tuplev(t_array, $aint), $array);
sig ('Array::extract',           $array, t_int, t_int,     $array);
sig ('Array::diff',              $array, $array, t_sub,    $array);
sig ('Array::shuffle',           $array,                   $array);
sig ('Array::fill_blanks',       $aoa,   t_sub,              $aoa);
sig ('Array::trim',              $astr,                     $astr);
sig ('Array::transpose',         $aoa,                       $aoa);

### SIDE-EFFECTS

sig('Array::iter',     $array, $sub, t_void);
sig('Array::iteri',    $array, $sub, t_void);
sig('Array::iter2d',   $aoa,   $sub, t_void);

### CONVERTER

sig('Array::fold',       $array, $any, $sub,           $any);
sig('Array::fold_mut',   $array, $any, $sub,           $any);
sig('Array::reduce',     $array, $sub,                 t_opt);
sig('Array::length',     $array,                       t_int);
#sig('Array::expand',   $array, ...);
sig('Array::first',      $array,                       t_opt);
sig('Array::last',       $array,                       t_opt);
sig('Array::sum',        $anum,                        t_num);
sig('Array::sum_by',     $array, $sub,                 t_num);
sig('Array::join',       $astr, t_str,                 t_str);
sig('Array::split',      $array, t_or(t_regex, t_str), t_array(t_of $astr));
sig('Array::min',        $astr,                        t_opt(t_num));
sig('Array::min_by',     $array, $sub,                 t_opt);
sig('Array::min_str',    $astr,                        t_opt(t_str));
sig('Array::min_str_by', $array, $sub,                 t_opt);
sig('Array::max',        $anum,                        t_opt(t_num));
sig('Array::max_by',     $array, $sub,                 t_opt);
sig('Array::max_str',    $astr,                        t_opt(t_str));
sig('Array::max_str_by', $array, $sub,                 t_opt);
sig('Array::group_fold', $array, $sub, $sub, $sub,     t_hash);
sig('Array::to_hash',    $array, $sub,                 t_hash);
sig('Array::to_hash_of_array', $array, $sub,           $hoa);
sig('Array::as_hash',    t_even_sized,                 t_hash);
sig('Array::keyed_by',   $array, $sub,                 t_hash);
sig('Array::group_by',   $array, $sub,                 $hoa);
sig('Array::count',      $array,                       t_hash(t_of t_int));
sig('Array::count_by',   $array, $sub,                 t_hash(t_of t_int));
sig('Array::find',       $array, $sub,                 t_opt);
sig('Array::any',        $array, $sub,                 t_bool);
sig('Array::all',        $array, $sub,                 t_bool);
sig('Array::none',       $array, $sub,                 t_bool);
sig('Array::pick',       $array, $sub,                 t_opt);
sig('Array::to_seq',     $array,                       t_seq);
sigt('Array::dump',
    t_or(
        t_tuple($array),
        t_tuple($array, t_int),
        t_tuple($array, t_int, t_int),
    ),
    t_str
);
sigt('Array::dumpw',
    t_or(
        t_tuple($array),
        t_tuple($array, t_int),
        t_tuple($array, t_int, t_int),
    ),
    t_void
);

# Functions from Option
sig('Array::all_some',     $aopt,        $opt);
sig('Array::all_some_by',  $array, $sub, $opt);
sig('Array::keep_some',    $aopt,        $array);
sig('Array::keep_some_by', $array, $sub, $array);

### MUTATION

sigt('Array::push',        t_tuplev($array, $array),            t_void);
sig ('Array::pop',         $array,                                $any);
sig ('Array::shift',       $array,                                $any);
sigt('Array::unshift',     t_tuplev($array, $array),            t_void);
sig ('Array::blit',        $array, t_int, $array, t_int, t_int, t_void);
sig ('Array::shuffle_mut', $array,                              t_void);

1;