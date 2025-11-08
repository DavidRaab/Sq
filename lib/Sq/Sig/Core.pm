package Sq::Sig::Core;
use 5.036;
use Sq::Type;
use Sq::Signature;

### OPTION MODULE

# Some predefined types
my $any       = t_any;
my $opt       = t_opt;
my $array     = t_array;
my $hash      = t_hash;
my $seq       = t_seq;
my $sub       = t_sub;
my $int       = t_int;
my $num       = t_num;
my $str       = t_str;
my $pint      = t_int(t_positive);

my $aoa       = t_array(t_of $array);
my $aoh       = t_array(t_of $hash);
my $aint      = t_array(t_of $int);
my $anum      = t_array(t_of $num);
my $astr      = t_array(t_of $str);
my $aopt      = t_array(t_of $opt);
my $aos       = t_array(t_of $seq);
my $ares      = t_array(t_of t_result);
my $kv        = t_tuple(t_str, $any);

my $hoa       = t_hash (t_of $array);
my $str_array = t_eq('Array');
my $str_seq   = t_eq('Seq');


sigt('Option::Some', t_tuplev(t_array), $opt);
# sigt('Option::None', t_tuple(),         $opt); # doesn't work because of Prototype

sig('Option::is_some', $any, t_bool);
sig('Option::is_none', $any, t_bool);

my $omatch = t_keys(
    Some => $sub,
    None => $sub,
);
sigt('Option::match', t_tuplev($opt, t_as_hash($omatch)), $any);

# Still need a solution for signature with list context
# sigt('Option::or',    t_tuplev($opt, t_array(t_min(1), t_of($any))), $any);
# sigt('Option::or_with', ...)

sig('Option::or_else',      $opt, $opt,                    $opt);
sig('Option::or_else_with', $opt, $sub,                   $opt);
sig('Option::bind',         $opt, $sub,                   $opt);
sig('Option::bind2',        $opt, $opt,             $sub, $opt);
sig('Option::bind3',        $opt, $opt, $opt,       $sub, $opt);
sig('Option::bind4',        $opt, $opt, $opt, $opt, $sub, $opt);
sigt('Option::bind_v',
    t_array(
        t_of (t_or($opt, $sub)), # this is not completely correct. only last one is sub
        t_idx(-1, $sub)          # expect last one as function
    ),
    $opt
);

sig('Option::map',         $opt, $sub,                   $opt);
sig('Option::map2',        $opt, $opt,             $sub, $opt);
sig('Option::map3',        $opt, $opt, $opt,       $sub, $opt);
sig('Option::map4',        $opt, $opt, $opt, $opt, $sub, $opt);
sigt('Option::map_v',
    t_array(
        t_of (t_or($opt, $sub)), # this is not completely correct. only last one is sub
        t_idx(-1, $sub)          # expect last one as function
    ),
    $opt
);

sig('Option::validate',  $opt, $sub,       $opt);
sig('Option::check',     $opt, $sub,       t_bool);
sig('Option::fold',      $opt, $any, $sub, $any);
sig('Option::fold_back', $opt, $any, $sub, $any);
sig('Option::iter',      $opt, $sub,       t_void);
sig('Option::single',    $opt,              t_opt(t_array));
sig('Option::to_array',  $opt,              t_array);
sig('Option::to_seq',    $opt,              t_seq);
# sig('Option::get', ... ) # list context

### Module Functions

# sigt('Option::extract',        t_tuplev($any, ), )  # list context


### RESULT MODULE
my $result = t_result;

sig('Result::map',          $result,                            $sub, $result);
sig('Result::map2',         $result, $result,                   $sub, $result);
sig('Result::map3',         $result, $result, $result,          $sub, $result);
sig('Result::map4',         $result, $result, $result, $result, $sub, $result);
sig('Result::mapErr',       $result,                            $sub, $result);
sig('Result::or_else',      $result, $result,                          $result);
sig('Result::or_else_with', $result, $sub,                            $result);

### SIDE-EFFECTS

sig('Result::iter',      $result, $sub, t_void);

### CONVERTERS
my $rmatch = t_keys(
    Ok  => $sub,
    Err => $sub,
);
sigt('Result::match',    t_tuplev($result, t_as_hash($rmatch)), $any);
sig('Result::fold',      $result, $any, $sub,                   $any);
sig('Result::is_ok',     $any,                                 t_bool);
sig('Result::is_err',    $any,                                 t_bool);
sig('Result::or',        $result, $any,                          $any);
sig('Result::or_with',   $result, $sub,                         $any);
sig('Result::to_option', $result,                               t_opt);
sig('Result::to_array',  $result,                             t_array);
sig('Result::value',     $result,                                $any);
sig('Result::get',       $result,                                $any);


###----------------------
### ARRAY
###----------------------

### CONSTRUCTORS

sigt('Array::new',        t_tuplev($str_array, $array),    $array);
sigt('Array::concat',     t_tuplev($str_array, $aoa),      $array);
sig ('Array::empty',      $str_array,                      $array);
sig ('Array::replicate',  $pint, $any,                 $array);
sig ('Array::bless',      $str_array, $array,              $array);
sig ('Array::from_array', $str_array, $array,              $array);
sig ('Array::init',       $pint, $sub,                 $array);
sig ('Array::init2d',     $pint, $pint, $sub,          $array);
# Second argument is 'State, would be good to back-reference the type
sig ('Array::unfold',     $str_array, $any, $sub,          $array);
sig ('Array::range_step', $str_array, t_num, t_num, t_num, $array);
sig ('Array::range',      $str_array, t_int, t_int,        $array);
sig ('Array::one',        $str_array, $any,                $array);


### METHODS

sig ('Array::copy',          $array,                               $array);
sig ('Array::bind',          $array, $sub,                         $array);
sig ('Array::flatten',       $aoa,                                 $array);
sig ('Array::merge',         $aoa,                                 $array);
sigt('Array::cartesian',     t_array(t_of t_array(t_min 1)),         $aoa);
sig ('Array::append',        $array, $array,                       $array);
sig ('Array::rev',           $array,                               $array);
sig ('Array::map',           $array, $sub,                         $array);
sig ('Array::map_rec',       $array, $sub,                         $array);
sig ('Array::map2',          $array, $array, $sub,                 $array);
sig ('Array::map3',          $array, $array, $array, $sub,         $array);
sig ('Array::map4',          $array, $array, $array, $array, $sub, $array);
sig ('Array::map_e',         $array, t_str,                        $array);
sig ('Array::map2d',         $aoa,   $sub,                           $aoa);
sig ('Array::mapi',          $array, $sub,                         $array);
sig ('Array::mapn',          $array, $pint, $sub,                  $array);
sig ('Array::choose',        $array, $sub,                         $array);
sig ('Array::keep',          $array, $sub,                         $array);
sig ('Array::keep_type',     $array, $sub,                         $array);
sig ('Array::keep_ok',       t_array(t_of t_result),               $array);
sig ('Array::keep_ok_by',    t_array, $sub,                        $array);
sig ('Array::keep_e',        $array, t_str,                        $array);
sig ('Array::remove',        $array, $sub,                         $array);
sig ('Array::skip',          $array, $pint,                        $array);
sig ('Array::take',          $array, $pint,                        $array);
sig ('Array::indexed',       $array,          t_array(t_of t_tuple($any, t_int)));
sigt('Array::zip',           t_array(t_of $array),                   $aoa);
sig ('Array::sort',          $array, $sub,                         $array);
sig ('Array::sort_by',       $array, $sub, $sub,                   $array);
sig ('Array::sort_hash',     $array, $sub, t_str,                  $array);
sig ('Array::fsts',          $aoa,                                 $array);
sig ('Array::snds',          $aoa,                                 $array);
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
sig ('Array::permute',           $array,                     $aoa);
sig ('Array::chunked_size',      $array, $pint, $sub,      $array);
sig ('Array::tail',              t_array(t_min 1),         $array);


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

sig('Array::is_empty',   $array,                      t_bool);
sig('Array::fold',       $array, $any, $sub,            $any);
sig('Array::fold_mut',   $array, $any, $sub,            $any);
sig('Array::scan',       $array, $any, $sub,         t_array);
sig('Array::average',    $array,                       t_num);
sig('Array::average_by', $array, $sub,                 t_num);
sigt('Array::index',
    t_or(
        t_tuple($array, t_int),
        t_tuple($array, t_int, $any),
    ),
    $any);
sig('Array::reduce',     $array, $sub,                  $opt);
sig('Array::length',     $array,                       $pint);
#sig('Array::expand',   $array, ...);
sigt('Array::first',
    t_or(
        t_tuple($array),      # either 1 arg, an array
        t_tuple($array, $any) # or 2 args, array and anything else
    ),
    # TODO: This should improve. input should be mappable to output
    #       this currently makes less sense, also could be just $any.
    t_or(
        t_opt, # either returns optional
        $any   # or any
    )
);
sigt('Array::last',
    t_or(
        t_tuple($array),      # either 1 arg, an array
        t_tuple($array, $any) # or 2 args, array and anything else
    ),
    t_or(
        t_opt, # either returns optional
        $any   # or any
    )
);
sig('Array::sum',        $anum,                        t_num);
sig('Array::sum_by',     $array, $sub,                 t_num);
sigt('Array::join',
    t_or(
        t_tuple($astr),
        t_tuple($astr, t_str),
    ), t_str);
sig('Array::split',      $astr, t_regex,              t_array(t_of $astr));
sigt('Array::min',
    t_or(t_tuple($anum), t_tuple($anum, $any)),
    t_or(t_opt(t_num),   t_num));
sigt('Array::min_str',
    t_or(t_tuple($astr), t_tuple($astr, $any)),
    t_or(t_opt(t_str), t_str));
sig('Array::min_by',     $array, $sub,                 $opt);
sig('Array::min_str_by', $array, $sub,                 $opt);
sigt('Array::max',
    t_or(t_tuple($anum), t_tuple($anum, $any)),
    t_or(t_opt(t_num), t_num));
sigt('Array::max_str',
    t_or(t_tuple($astr), t_tuple($astr, $any)),
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
sigt('Array::contains',  t_tuplev($array, $array),     t_bool);
sig('Array::fold_rec',   $array, $sub, $sub,           $any);
sig('Array::map_array',  $array, $sub, $sub,           $any);
sig('Array::head',       t_array(t_min 1),             $any);


### OPTION MODULE

sig('Array::all_some',     $aopt,        $opt);
sig('Array::all_some_by',  $array, $sub, $opt);
sig('Array::all_ok',       $ares,        t_opt(t_array));
sig('Array::all_ok_by',    $array, $sub, t_opt(t_array));
sig('Array::keep_some',    $aopt,        $array);
sig('Array::keep_some_by', $array, $sub, $array);


### MUTATION

sigt('Array::push',        t_tuplev($array, $array),            t_void);
sig ('Array::pop',         $array,                                $any);
sig ('Array::shift',       $array,                                $any);
sigt('Array::unshift',     t_tuplev($array, $array),            t_void);
sig ('Array::blit',        $array, t_int, $array, t_int, t_int, t_void);



###---------------------
### HASH
###---------------------

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



###--------------------------
### SEQUENCE
###--------------------------

### CONSTRUCTORS

sig ('Seq::from_sub',   $str_seq,  $sub,               $seq);
sig ('Seq::always',     $str_seq, $any,                $seq);
sig ('Seq::empty',      $str_seq,                      $seq);
sig ('Seq::replicate',  $str_seq, t_int, $any,         $seq);
sig ('Seq::unfold',     $str_seq, $any,  $sub,         $seq);
sig ('Seq::init',       $str_seq, t_int,  $sub,        $seq);
sig ('Seq::range_step', $str_seq, t_num, t_num, t_num, $seq);
sigt('Seq::new',        t_tuplev($str_seq, t_array),   $seq);
sig ('Seq::range',      $str_seq, t_int, t_int,        $seq);
sig ('Seq::from_array', $str_seq, t_array,             $seq);
sig ('Seq::from_hash',  $str_seq, t_hash,  $sub,       $seq);
sigt('Seq::concat',     t_tuplev($str_seq, $aos),      $seq);
sig ('Seq::up',         $str_seq, t_int,               $seq);
sig ('Seq::down',       $str_seq, t_int,               $seq);
sig ('Seq::one',        $str_seq, $any,                $seq);

### METHODS

sig('Seq::copy',          $seq,                 $seq);
sig('Seq::append',        $seq, $seq,           $seq);
sig('Seq::map',           $seq, $sub,           $seq);
sig('Seq::map2',          $seq, $seq, $sub,     $seq);
sig('Seq::bind',          $seq, $sub,           $seq);
sig('Seq::flatten',       $seq,                 $seq);
sig('Seq::merge',         $seq,                 $seq);
sigt('Seq::cartesian',    t_array(t_of $seq),   $seq);
sig('Seq::left_join',     $seq, $seq, $sub,     $seq);
# sig('Seq::merge',         $seq, $sub,           $seq);
sig('Seq::select',        $seq, $any, $any,     $seq);
sig('Seq::choose',        $seq, $sub,           $seq);
sig('Seq::mapi',          $seq, $sub,           $seq);
sig('Seq::keep',          $seq, $sub,           $seq);
sig('Seq::remove',        $seq, $sub,           $seq);
sig('Seq::take',          $seq, t_int,          $seq);
sig('Seq::take_while',    $seq, $sub,           $seq);
sig('Seq::skip',          $seq, t_int,          $seq);
sig('Seq::skip_while',    $seq, $sub,           $seq);
sig('Seq::indexed',       $seq,                 $seq);
sig('Seq::distinct_by',   $seq, $sub,           $seq);
sig('Seq::distinct',      $seq,                 $seq);
sig('Seq::fsts',          $seq,                 $seq);
sig('Seq::snds',          $seq,                 $seq);
sigt('Seq::zip',          t_array(t_of t_seq),  $seq);
sig('Seq::rev',           $seq,                 $seq);
sig('Seq::cache',         $seq,                 $seq);
sig('Seq::rx',            $seq, t_regex,        $seq);
sig('Seq::rxm',           $seq, t_regex,        $seq);
sig('Seq::rxs',           $seq, t_regex, $sub, $seq);
sig('Seq::rxsg',          $seq, t_regex, $sub, $seq);
sig('Seq::chunked',       $seq, t_int,          $seq);
sig('Seq::windowed',      $seq, t_int,          $seq);
sig('Seq::intersperse',   $seq, $any,           $seq);
sig('Seq::infinity',      $seq,                 $seq);
sig('Seq::repeat',        $seq, t_int,          $seq);
sig('Seq::trim',          $seq,                 $seq);
sig('Seq::permute',       $seq,                 $seq);
sig('Seq::tail',          $seq,                 $seq);

# sig('Seq::sort_hash_str', $aoh,    t_str,        $aoh);
# sigt('Seq::slice',             t_tuplev($seq, $aint), $seq);
# sig ('Seq::extract',           $seq, t_int, t_int,    $seq);


### SIDE-EFFECTS

sig('Seq::iter',     $seq, $sub,      t_void);
sig('Seq::iteri',    $seq, $sub,      t_void);
sig('Seq::do',       $seq, $sub,        $seq);
sig('Seq::do_every', $seq, t_int, $sub, $seq);
sig('Seq::doi',      $seq, $sub,        $seq);

### CONVERTER

sig('Seq::is_empty',   $seq,                   t_bool);
sig('Seq::head',       $seq,                     $any);
sig('Seq::sort',       $seq, $sub,            t_array);
sig('Seq::sort_by',    $seq, $sub, $sub,      t_array);
sig('Seq::group_fold', $seq, $sub, $sub, $sub, t_hash);
sig('Seq::group_by',   $seq, $sub,               $hoa);
sig('Seq::fold',       $seq, $any, $sub,         $any);
sig('Seq::fold_mut',   $seq, $any, $sub,         $any);
sig('Seq::reduce',     $seq, $sub,               $opt);
sigt('Seq::first',
    t_or(t_tuple($seq), t_tuple($seq, $any)),
    t_or($opt, $any)
);
sigt('Seq::last',
    t_or(t_tuple($seq), t_tuple($seq, $any)),
    t_or($opt, $any)
);
sig('Seq::contains',   $seq, $any,             t_bool);
sigt('Seq::to_array',
    t_or(
        t_tuple($seq),
        t_tuple($seq, t_int),
    ),
    t_array
);
sigt('Seq::index',
    t_or(
        t_tuple($seq, t_int),
        t_tuple($seq, t_int, $any),
    ),
    $any);
sig('Seq::to_arrays',  $any, $any);
sig('Seq::to_seq',     $seq, $seq);
#sig('Seq::expand',    $seq, ...);
sig('Seq::length',     $seq,                       t_int);
sig('Seq::sum',        $seq,                       t_num);
sig('Seq::sum_by',     $seq, $sub,                 t_num);
sig('Seq::min',        $seq,                       t_opt(t_num));
sig('Seq::min_by',     $seq, $sub,                 $opt);
sig('Seq::min_str',    $seq,                       t_opt(t_str));
sig('Seq::min_str_by', $seq, $sub,                 $opt);
sig('Seq::max',        $seq,                       t_opt(t_num));
sig('Seq::max_by',     $seq, $sub,                 $opt);
sig('Seq::max_str',    $seq,                       t_opt(t_str));
sig('Seq::max_str_by', $seq, $sub,                 $opt);
sigt('Seq::join',
    t_or(
        t_tuple($seq),
        t_tuple($seq, t_str),
    ),
    t_str);
sig('Seq::split',      $seq, t_regex,              $seq);
sig('Seq::as_hash',    $seq,                       t_hash);
sig('Seq::to_hash',    $seq, $sub,                 t_hash);
sig('Seq::to_hash_of_array',  $seq, $sub,          $hoa);
sig('Seq::to_array_of_array', $seq,                $aoa);
sig('Seq::find',       $seq, $sub,                 $opt);
sig('Seq::any',        $seq, $sub,                 t_bool);
sig('Seq::all',        $seq, $sub,                 t_bool);
sig('Seq::none',       $seq, $sub,                 t_bool);
sig('Seq::pick',       $seq, $sub,                 $opt);
sig('Seq::equal',      $seq, $any,                 $any);
sig('Seq::count',      $seq,                       t_hash(t_of t_int));
sig('Seq::count_by',   $seq, $sub,                 t_hash(t_of t_int));
sig('Seq::intersect',  $seq, $seq, $sub,           t_array);

1;