package Sq::Sig::Array;
use 5.036;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $array = t_array;
my $hash  = t_hash;
my $aoa   = t_array(t_of t_array);
my $aoh   = t_array(t_of t_hash);
my $hoa   = t_hash (t_of t_array);
my $aint  = t_array(t_of t_int);
my $anum  = t_array(t_of t_num);
my $astr  = t_array(t_of t_str);
my $any   = t_any;
my $opt   = t_opt;
my $sub   = t_sub;
my $aopt  = t_array(t_of $opt);
my $pint  = t_int(t_positive);
my $class = t_enum('Array');

### CONSTRUCTORS

sigt('Array::new',        t_tuplev($class, $array),    $array);
sigt('Array::concat',     t_tuplev($class, $aoa),      $array);
sig ('Array::empty',      $class,                      $array);
sig ('Array::replicate',  $pint, $any,               $array);
sig ('Array::bless',      $class, $array,              $array);
sig ('Array::from_array', $class, $array,              $array);
sig ('Array::init',       $pint, $sub,               $array);
sig ('Array::init2d',     $pint, $pint, $sub,        $array);
# Second argument is 'State, would be good to back-reference the type
sig ('Array::unfold',     $class, $any, $sub,          $array);
sig ('Array::range_step', $class, t_num, t_num, t_num, $array);
sig ('Array::range',      $class, t_int, t_int,        $array);


### METHODS

sig ('Array::copy',          $array,                       $array);
sig ('Array::bind',          $array, $sub,                 $array);
sig ('Array::flatten',       $aoa,                         $array);
sig ('Array::merge',         $aoa,                         $array);
sig ('Array::cartesian',     $array, $array,               t_array(t_of t_tuple($any, $any)));
sig ('Array::append',        $array, $array,               $array);
sig ('Array::rev',           $array,                       $array);
sig ('Array::map',           $array, $sub,                 $array);
sig ('Array::map2',          $array, $array, $sub,         $array);
sig ('Array::map3',          $array, $array, $array, $sub, $array);
sig ('Array::map_e',         $array, t_str,                $array);
sig ('Array::map2d',         $aoa,   $sub,                   $aoa);
sig ('Array::choose',        $array, $sub,                 $array);
sig ('Array::mapi',          $array, $sub,                 $array);
sig ('Array::keep',          $array, $sub,                 $array);
sig ('Array::keep_type',     $array, $sub,                 $array);
sig ('Array::keep_ok',       t_array(t_of t_result),       $array);
sig ('Array::keep_ok_by',    t_array, $sub,                $array);
sig ('Array::keep_e',        $array, t_str,                $array);
sig ('Array::remove',        $array, $sub,                 $array);
sig ('Array::skip',          $array, $pint,                $array);
sig ('Array::take',          $array, $pint,                $array);
sig ('Array::indexed',       $array,                       t_array(t_of t_tuple($any, t_int)));
sigt('Array::zip',           t_array(t_of $array),           $aoa);
sig ('Array::sort',          $array, $sub,                 $array);
sig ('Array::sort_by',       $array, $sub, $sub,           $array);
sig ('Array::sort_hash',     $array, $sub, t_str,          $array);
sig ('Array::fsts',          $aoa,                         $array);
sig ('Array::snds',          $aoa,                         $array);
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
sig ('Array::rx',                $astr,  t_regex,           $astr);
sig ('Array::rxm',               $astr,  t_regex,          t_array(t_of $astr));
sig ('Array::rxs',               $astr,  t_regex, $sub,     $astr);
sig ('Array::rxsg',              $astr,  t_regex, $sub,     $astr);
sig ('Array::chunked',           $array, $pint,              $aoa);
sig ('Array::windowed',          $array, $pint,              $aoa);
sig ('Array::intersperse',       $array, $any,             $array);
sig ('Array::repeat',            $array, $pint,            $array);
sig ('Array::take_while',        $array, $sub,             $array);
sig ('Array::skip_while',        $array, $sub,             $array);
sigt('Array::slice',             t_tuplev(t_array, $aint), $array);
sig ('Array::extract',           $array, $pint, $pint,     $array);
sig ('Array::diff',              $array, $array, $sub,     $array);
sig ('Array::intersect',         $array, $array, $sub,     $array);
sig ('Array::shuffle',           $array,                   $array);
sig ('Array::trim',              $astr,                     $astr);
sig ('Array::cache',             $array,                   $array);
sig ('Array::fill',              $array, $pint, $sub,      $array);

### ARRAY 2D

sig ('Array::fill2d',            $aoa, $sub,              $aoa);
sig ('Array::transpose',         $aoa,                    $aoa);
sig ('Array::transpose_map',     $aoa, $sub,              $aoa);
sig ('Array::columns',           $array, $pint,           $aoa);


### SIDE-EFFECTS

sig('Array::iter',      $array, $sub,        t_void);
sig('Array::itern',     $array, $pint, $sub, t_void);
sig('Array::iteri',     $array, $sub,        t_void);
sig('Array::iter2d',    $aoa,   $sub,        t_void);
sig('Array::iter_sort', $array, $sub, $sub,  t_void);


### CONVERTER

sig('Array::fold',       $array, $any, $sub,            $any);
sig('Array::fold_mut',   $array, $any, $sub,            $any);
sig('Array::scan',       $array, $any, $sub,         t_array);
sig('Array::average',    $array,                       t_num);
sig('Array::average_by', $array, $sub,                 t_num);
sig('Array::reduce',     $array, $sub,                  $opt);
sig('Array::length',     $array,                       $pint);
#sig('Array::expand',   $array, ...);
sig('Array::first',      $array,                       $opt);
sig('Array::last',       $array,                       $opt);
sig('Array::sum',        $anum,                        t_num);
sig('Array::sum_by',     $array, $sub,                 t_num);
sigt('Array::join',
    t_or(
        t_tuple($astr),
        t_tuple($astr, t_str),
    ), t_str);
sig('Array::split',      $astr, t_regex,              t_array(t_of $astr));
sigt('Array::min',
    t_or(t_tuple($anum), t_tuple($anum, t_any)),
    t_or(t_opt(t_num), t_num));
sigt('Array::min_str',
    t_or(t_tuple($astr), t_tuple($astr, t_any)),
    t_or(t_opt(t_str), t_str));
sig('Array::min_by',     $array, $sub,                 $opt);
sig('Array::min_str_by', $array, $sub,                 $opt);
sigt('Array::max',
    t_or(t_tuple($anum), t_tuple($anum, t_any)),
    t_or(t_opt(t_num), t_num));
sigt('Array::max_str',
    t_or(t_tuple($astr), t_tuple($astr, t_any)),
    t_or(t_opt(t_str), t_str));
sig('Array::max_by',     $array, $sub,                 $opt);
sig('Array::max_str_by', $array, $sub,                 $opt);
sig('Array::group_fold', $array, $sub, $sub, $sub,     $hash);
sig('Array::to_hash',    $array, $sub,                 $hash);
sig('Array::to_hash_of_array', $array, $sub,           $hoa);
sig('Array::as_hash',    t_even_sized,                 $hash);
sig('Array::keyed_by',   $array, $sub,                 $hash);
sig('Array::group_by',   $array, $sub,                 $hoa);
sig('Array::count',      $array,                       t_hash(t_of t_int));
sig('Array::count_by',   $array, $sub,                 t_hash(t_of t_int));
sig('Array::find',       $array, $sub,                 $opt);
sig('Array::any',        $array, $sub,                 t_bool);
sig('Array::all',        $array, $sub,                 t_bool);
sig('Array::none',       $array, $sub,                 t_bool);
sig('Array::pick',       $array, $sub,                 $opt);
sig('Array::to_seq',     $array,                       t_seq);
sig('Array::contains',   $array, $any,                 t_bool);


### OPTION MODULE

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

1;