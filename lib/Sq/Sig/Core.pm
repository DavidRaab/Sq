package Sq::Sig::Core;
use 5.036;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $any       = t_any;
my $void      = t_void;
my $opt       = t_opt;
my $array     = t_array;
my $hash      = t_hash;
my $seq       = t_seq;
my $sub       = t_sub;
my $bool      = t_bool;
my $int       = t_int;
my $num       = t_num;
my $str       = t_str;
my $regex     = t_regex;
my $pint      = t_int(t_positive);

my $aoa        = t_aoa;
my $aoh        = t_array(t_of $hash);
my $aint       = t_array(t_of $int);
my $anum       = t_array(t_of $num);
my $astr       = t_array(t_of $str);
my $aopt       = t_array(t_of $opt);
my $aos        = t_array(t_of $seq);
my $ares       = t_array(t_of t_result);
my $even_sized = t_even_sized;
my $kv         = t_tuple($str, $any);

my $hoa       = t_hash (t_of $array);
my $str_array = t_eq('Array');
my $str_seq   = t_eq('Seq');

# Sq main function

# Need to look how Prototype is reserved
# sig('Sq::key', $str, $sub);

sig('Sq::key_equal', $str, $any, $sub);
sigt('Sq::record',   t_of($str), $sub);
sigt('Sq::dispatch',
    t_tuple ($sub, t_hash(t_of $sub))                        => $sub,
    t_tuplev($str, $str, $sub, $str, $sub, t_of($str, $sub)) => $any,
);

### OPTION MODULE

sigt('Option::Some', t_tuplev($array), $opt);
# sigt('Option::None', t_tuple(),         $opt); # doesn't work because of Prototype

sig('Option::is_some', $any, $bool);
sig('Option::is_none', $any, $bool);

my $omatch = t_keys(
    Some => $sub,
    None => $sub,
);
sigt('Option::match', t_tuplev($opt, t_as_hash($omatch)), $any);

# Still need a solution for signature with list context
# sigt('Option::or',    t_tuplev($opt, t_array(t_min(1), t_of($any))), $any);
# sigt('Option::or_with', ...)

sig('Option::or_else',      $opt, $opt,                   $opt);
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
sig('Option::check',     $opt, $sub,       $bool);
sig('Option::fold',      $opt, $any, $sub, $any);
sig('Option::fold_back', $opt, $any, $sub, $any);
sig('Option::iter',      $opt, $sub,       $void);
sig('Option::single',    $opt,             t_opt($array));
sig('Option::to_array',  $opt,             $array);
sig('Option::to_seq',    $opt,             $seq);
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
sig('Result::or_else',      $result, $result,                         $result);
sig('Result::or_else_with', $result, $sub,                            $result);

### SIDE-EFFECTS

sig('Result::iter',      $result, $sub, $void);

### CONVERTERS
my $rmatch = t_keys(
    Ok  => $sub,
    Err => $sub,
);
sigt('Result::match',    t_tuplev($result, t_as_hash($rmatch)), $any);
sig('Result::fold',      $result, $any, $sub,                   $any);
sig('Result::is_ok',     $any,                                 $bool);
sig('Result::is_err',    $any,                                 $bool);
sig('Result::or',        $result, $any,                         $any);
sig('Result::or_with',   $result, $sub,                         $any);
sig('Result::to_option', $result,                               $opt);
sig('Result::to_array',  $result,                             $array);
sig('Result::value',     $result,                               $any);
sig('Result::get',       $result,                               $any);


###----------------------
### ARRAY
###----------------------

### CONSTRUCTORS

sigt('Array::new',        t_tuplev($str_array, $array),    $array);
sigt('Array::concat',     $aoa,                            $array);
sig ('Array::empty',      $str_array,                      $array);
sig ('Array::replicate',  $pint, $any,                     $array);
sig ('Array::bless',      $str_array, $array,              $array);
sig ('Array::from_array', $str_array, $array,              $array);
sig ('Array::init',       $pint, $any,                     $array);
sig ('Array::init2d',     $pint, $pint, $sub,              $array);
# Second argument is 'State, would be good to back-reference the type
sig ('Array::unfold',     $str_array, $any, $sub,          $array);
sig ('Array::range_step', $str_array, $num, $num, $num,    $array);
sig ('Array::range',      $str_array, $int, $int,          $array);
sig ('Array::one',        $str_array, $any,                $array);


### METHODS

sig ('Array::bind',          $array, $sub,                         $array);
sig ('Array::flatten',       $aoa,                                 $array);
sig ('Array::merge',         $aoa,                                 $array);
sigt('Array::cartesian',     t_aoa,                                  $aoa);
sigt('Array::combine',       t_tuplev($aoh, $sub, $astr),          $array);
sig ('Array::append',        $array, $array,                       $array);
sig ('Array::rev',           $array,                               $array);
sig ('Array::map',           $array, $sub,                         $array);
sig ('Array::map_rec',       $array, $sub,                         $array);
sig ('Array::map2',          $array, $array, $sub,                 $array);
sig ('Array::map3',          $array, $array, $array, $sub,         $array);
sig ('Array::map4',          $array, $array, $array, $array, $sub, $array);
sig ('Array::map_e',         $array, $str,                         $array);
sig ('Array::map2d',         $aoa,   $sub,                           $aoa);
sig ('Array::mapi',          $array, $sub,                         $array);
sig ('Array::mapn',          $array, $pint, $sub,                  $array);
sig ('Array::choose',        $array, $sub,                         $array);
sig ('Array::keep',          $array, $sub,                         $array);
sig ('Array::keep_type',     $array, $sub,                         $array);
sig ('Array::keep_ok',       $ares,                                $array);
sig ('Array::keep_ok_by',    $array, $sub,                         $array);
sig ('Array::keep_e',        $array, $str,                        $array);
sig ('Array::remove',        $array, $sub,                         $array);
sig ('Array::skip',          $array, $pint,                        $array);
sig ('Array::take',          $array, $pint,                        $array);
sig ('Array::indexed',       $array,    t_array(t_of t_tuple($any, $int)));
sigt('Array::zip',           $aoa,                                   $aoa);
sig ('Array::sort',          $array, $sub,                         $array);
sig ('Array::sort_by',       $array, $sub, $sub,                   $array);
sig ('Array::sort_hash',     $array, $sub, $str,                   $array);
sig ('Array::fsts',          $aoa,                                 $array);
sig ('Array::snds',          $aoa,                                 $array);
sigt('Array::to_array',      t_tuplen(1, $array, $int),            $array);
sig ('Array::to_array_of_array', $aoa,                         $aoa);
sig ('Array::distinct',          $array,                     $array);
sig ('Array::distinct_by',       $array, $sub,               $array);
sig ('Array::rx',                $astr,  $regex,              $astr);
sig ('Array::rxm',               $astr,  $regex,       t_aoa(t_str));
sig ('Array::rxs',               $astr,  $regex, $sub,        $astr);
sig ('Array::rxsg',              $astr,  $regex, $sub,        $astr);
sig ('Array::chunked',           $array, $pint,                $aoa);
sig ('Array::windowed',          $array, $pint,                $aoa);
sig ('Array::intersperse',       $array, $any,               $array);
sig ('Array::repeat',            $array, $pint,              $array);
sig ('Array::take_while',        $array, $sub,               $array);
sig ('Array::skip_while',        $array, $sub,               $array);
sigt('Array::slice',             t_tuplev($array, $aint),    $array);
sig ('Array::extract',           $array, $pint, $pint,       $array);
sig ('Array::diff',              $array, $array, $sub,       $array);
sig ('Array::intersect',         $array, $array, $sub,       $array);
sig ('Array::shuffle',           $array,                     $array);
sig ('Array::trim',              $astr,                       $astr);
sig ('Array::cache',             $array,                     $array);
sig ('Array::fill',              $array, $pint, $any,        $array);
sig ('Array::permute',           $array,                       $aoa);
sig ('Array::chunked_size',      $array, $pint, $sub,        $array);
sig ('Array::tail',              t_array(t_min 1),           $array);


### ARRAY 2D

sig ('Array::fill2d',            $aoa, $any,              $aoa);
sig ('Array::transpose',         $aoa,                    $aoa);
sig ('Array::transpose_map',     $aoa, $sub,              $aoa);
sig ('Array::columns',           $array, $pint,           $aoa);


### SIDE-EFFECTS

sig('Array::iter',      $array, $sub,        $void);
sig('Array::itern',     $array, $pint, $sub, $void);
sig('Array::iteri',     $array, $sub,        $void);
sig('Array::iter2d',    $aoa,   $sub,        $void);
sig('Array::iter_sort', $array, $sub, $sub,  $void);


### CONVERTER

sig('Array::is_empty',   $array,                      $bool);
sig('Array::fold',       $array, $any, $sub,           $any);
sig('Array::fold_mut',   $array, $any, $sub,           $any);
sig('Array::scan',       $array, $any, $sub,         $array);
sig('Array::average',    $array,                       $num);
sig('Array::average_by', $array, $sub,                 $num);
sigt('Array::index',
    t_tuple($array, $int)       => $opt,
    t_tuple($array, $int, $any) => $any,
);
sig('Array::reduce',     $array, $sub,                  $opt);
sig('Array::length',     $array,                       $pint);
#sig('Array::expand',   $array, ...);
sigt('Array::first',
    t_tuple($array)       => $opt,
    t_tuple($array, $any) => $any,
);
sigt('Array::last',
    t_tuple($array)       => $opt,
    t_tuple($array, $any) => $any,
);
sig('Array::sum',        $anum,                    $num);
sig('Array::sum_by',     $array, $sub,             $num);
sigt('Array::join',      t_tuplen(1, $astr, $str), $str);
sig('Array::split',      $astr, $regex,    t_aoa(t_str));
sigt('Array::min',
    t_tuple($anum)       => t_opt($num),
    t_tuple($anum, $num) => $num,
);
sigt('Array::min_str',
    t_tuple($astr)       => t_opt($str),
    t_tuple($astr, $any) => $str,
);
sig('Array::min_by',     $array, $sub,                 $opt);
sig('Array::min_str_by', $array, $sub,                 $opt);
sigt('Array::max',
    t_tuple($anum)       => t_opt($num),
    t_tuple($anum, $any) => $num,
);
sigt('Array::max_str',
    t_tuple($astr)       => t_opt($str),
    t_tuple($astr, $any) => $str,
);
sig('Array::max_by',     $array, $sub,             $opt);
sig('Array::max_str_by', $array, $sub,             $opt);
sig('Array::group_fold', $array, $sub, $sub, $sub, $hash);
sig('Array::to_hash',    $array, $sub,             $hash);
sig('Array::to_hash_of_array', $array, $sub,       $hoa);
sig('Array::as_hash',    $even_sized,              $hash);
sig('Array::keyed_by',   $array, $sub,             $hash);
sig('Array::group_by',   $array, $sub,             $hoa);
sig('Array::count',      $array,                   t_hash(t_of $int));
sig('Array::count_by',   $array, $sub,             t_hash(t_of $int));
sig('Array::find',       $array, $sub,             $opt);
sig('Array::any',        $array, $sub,             $bool);
sig('Array::all',        $array, $sub,             $bool);
sig('Array::none',       $array, $sub,             $bool);
sig('Array::pick',       $array, $sub,             $opt);
sig('Array::to_seq',     $array,                   t_seq);
sigt('Array::contains',  t_tuplev($array, $array), $bool);
sig('Array::fold_rec',   $array, $sub, $sub,       $any);
sig('Array::map_array',  $array, $sub, $sub,       $any);
sig('Array::head',       t_array(t_min 1),         $any);


### OPTION MODULE

sig('Array::all_some',     $aopt,        $opt);
sig('Array::all_some_by',  $array, $sub, $opt);
sig('Array::all_ok',       $ares,        t_opt($array));
sig('Array::all_ok_by',    $array, $sub, t_opt($array));
sig('Array::keep_some',    $aopt,        $array);
sig('Array::keep_some_by', $array, $sub, $array);


### MUTATION

sigt('Array::push',        t_tuplev($array, $array),         $void);
sig ('Array::pop',         $array,                            $any);
sig ('Array::shift',       $array,                            $any);
sigt('Array::unshift',     t_tuplev($array, $array),         $void);
sig ('Array::blit',        $array, $int, $array, $int, $int, $void);



###---------------------
### HASH
###---------------------

### CONSTRUCTORS

sig ('Hash::empty',      $any,                        $hash);
sigt('Hash::new',        t_tuplev($any, $even_sized), $hash);
sig ('Hash::bless',      $any, $hash,                 $hash);
sig ('Hash::locked',     $any, $hash,                 $hash);
sig ('Hash::init',       $any, $int, $sub,            $hash);
sig ('Hash::from_array', $any, $array, $sub,          $hash);

### METHODS

sig ('Hash::keys',         $hash,                 $astr);
sig ('Hash::values',       $hash,                 $array);
sig ('Hash::map',          $hash, $sub,           $hash);
sig ('Hash::find',         $hash, $sub,           t_opt($kv));
sig ('Hash::pick',         $hash, $sub,           $opt);
sig ('Hash::keep',         $hash, $sub,           $hash);
sig ('Hash::fold',         $hash, $any, $sub,     $any);
sig ('Hash::fold_back',    $hash, $any, $sub,     $any);
sig ('Hash::length',       $hash,                 $int);
sig ('Hash::is_empty',     $hash,                 $bool);
sig ('Hash::bind',         $hash, $sub,           $hash);
sig ('Hash::append',       $hash, $hash,          $hash);
sig ('Hash::union',        $hash, $hash, $sub,    $hash);
sig ('Hash::intersect',    $hash, $hash, $sub,    $hash);
sig ('Hash::diff',         $hash, $hash,          $hash);
sigt('Hash::concat',       t_tuplev($hash, $aoh), $hash);
sig ('Hash::is_subset_of', $hash, $hash,          $int);
sig ('Hash::get',          $hash, $str,           $opt);
sigt('Hash::rename_keys',  t_tuplev($hash, t_as_hash(t_of t_str)),         $hash);
sigt('Hash::extract',      t_tuplev($hash, t_array(t_min(1), t_of $str)),  $aopt);
sigt('Hash::slice',        t_tuplev($hash, t_array(t_min(1), t_of $str)),  $hash);
sigt('Hash::with',         t_tuplev($hash, $even_sized),                   $hash); # can be improved
sigt('Hash::withf',        t_tuplev($hash, $even_sized),                   $hash); # can be improved
sigt('Hash::has_keys',     t_tuplev($hash, $astr),                         $bool);
sig ('Hash::to_array',     $hash, $sub,                                    $array);

### SIDE-EFFECTS

sigt('Hash::on',        t_tuplev($hash, $even_sized), $void);
sig ('Hash::iter',      $hash, $sub,                  $void);
sig ('Hash::iter_sort', $hash, $sub, $sub,            $void);
sigt('Hash::lock',      t_tuplev($hash, $astr),       $hash);

### MUTATION METHODS

sigt('Hash::set',     t_tuplev($hash, $even_sized),                  $void);
sigt('Hash::change',  t_tuplev($hash, $even_sized),                  $void);
sigt('Hash::push',    t_tuplev($hash, $str, t_min 1),                $void);
sigt('Hash::delete',  t_tuplev($hash, t_array(t_min(1), t_of $str)), $void);



###--------------------------
### SEQUENCE
###--------------------------

### CONSTRUCTORS

sig ('Seq::from_sub',   $str_seq, $sub,                $seq);
sig ('Seq::always',     $str_seq, $any,                $seq);
sig ('Seq::empty',      $str_seq,                      $seq);
sig ('Seq::replicate',  $str_seq, $int, $any,          $seq);
sig ('Seq::unfold',     $str_seq, $any,  $sub,         $seq);
sig ('Seq::init',       $str_seq, $int,  $any,         $seq);
sig ('Seq::range_step', $str_seq, $num, $num, $num,    $seq);
sigt('Seq::new',        t_tuplev($str_seq, $array),    $seq);
sig ('Seq::range',      $str_seq, $int, $int,          $seq);
sig ('Seq::from_array', $str_seq, $array,              $seq);
sig ('Seq::from_hash',  $str_seq, $hash,  $sub,        $seq);
sigt('Seq::concat',     t_tuplev($str_seq, $aos),      $seq);
sig ('Seq::up',         $str_seq, $int,                $seq);
sig ('Seq::down',       $str_seq, $int,                $seq);
sig ('Seq::one',        $str_seq, $any,                $seq);

### METHODS

sig('Seq::append',        $seq, $seq,               $seq);
sigt('Seq::combine', t_tuplev($seq, $sub, $astr), $array);
sig('Seq::map',           $seq, $sub,               $seq);
sig('Seq::map2',          $seq, $seq, $sub,         $seq);
sig('Seq::map3',          $seq, $seq, $seq, $sub,   $seq);
sig('Seq::bind',          $seq, $sub,               $seq);
sig('Seq::flatten',       $seq,                     $seq);
sig('Seq::merge',         $seq,                     $seq);
sigt('Seq::cartesian',    $aos,                     $seq);
sig('Seq::left_join',     $seq, $seq, $sub,         $seq);
# sig('Seq::merge',         $seq, $sub,               $seq);
sig('Seq::select',        $seq, $any, $any,         $seq);
sig('Seq::choose',        $seq, $sub,               $seq);
sig('Seq::mapi',          $seq, $sub,               $seq);
sig('Seq::keep',          $seq, $sub,               $seq);
sig('Seq::remove',        $seq, $sub,               $seq);
sig('Seq::take',          $seq, $int,               $seq);
sig('Seq::take_while',    $seq, $sub,               $seq);
sig('Seq::skip',          $seq, $int,               $seq);
sig('Seq::skip_while',    $seq, $sub,               $seq);
sig('Seq::indexed',       $seq,                     $seq);
sig('Seq::distinct_by',   $seq, $sub,               $seq);
sig('Seq::distinct',      $seq,                     $seq);
sig('Seq::fsts',          $seq,                     $seq);
sig('Seq::snds',          $seq,                     $seq);
sigt('Seq::zip',          $aos,                     $seq);
sig('Seq::rev',           $seq,                     $seq);
sig('Seq::cache',         $seq,                     $seq);
sig('Seq::rx',            $seq, $regex,             $seq);
sig('Seq::rxm',           $seq, $regex,             $seq);
sig('Seq::rxs',           $seq, $regex, $sub,       $seq);
sig('Seq::rxsg',          $seq, $regex, $sub,       $seq);
sig('Seq::chunked',       $seq, $int,               $seq);
sig('Seq::windowed',      $seq, $int,               $seq);
sig('Seq::find_windowed', $seq, $int, $sub,         t_opt(t_array));
sig('Seq::intersperse',   $seq, $any,               $seq);
sig('Seq::infinity',      $seq,                     $seq);
sig('Seq::repeat',        $seq, $int,               $seq);
sig('Seq::trim',          $seq,                     $seq);
sig('Seq::permute',       $seq,                     $seq);
sig('Seq::tail',          $seq,                     $seq);

# sig('Seq::sort_hash_str', $aoh,    $str,        $aoh);
# sigt('Seq::slice',             t_tuplev($seq, $aint), $seq);
# sig ('Seq::extract',           $seq, t_int, t_int,    $seq);


### SIDE-EFFECTS

sig('Seq::iter',     $seq, $sub,       $void);
sig('Seq::iteri',    $seq, $sub,       $void);
sig('Seq::itern',    $seq, $int, $sub, $void);
sig('Seq::do',       $seq, $sub,        $seq);
sig('Seq::do_every', $seq, $int, $sub,  $seq);
sig('Seq::doi',      $seq, $sub,        $seq);

### CONVERTER

sig('Seq::average',    $seq,                     $num);
sig('Seq::average_by', $seq, $sub,               $num);
sig('Seq::is_empty',   $seq,                    $bool);
sig('Seq::head',       $seq,                     $any);
sig('Seq::sort',       $seq, $sub,             $array);
sig('Seq::sort_by',    $seq, $sub, $sub,       $array);
sig('Seq::group_fold', $seq, $sub, $sub, $sub,  $hash);
sig('Seq::group_by',   $seq, $sub,               $hoa);
sig('Seq::fold',       $seq, $any, $sub,         $any);
sig('Seq::fold_mut',   $seq, $any, $sub,         $any);
sig('Seq::reduce',     $seq, $sub,               $opt);
sigt('Seq::first',
    t_tuple($seq)       => $opt,
    t_tuple($seq, $any) => $any,
);
sigt('Seq::last',
    t_tuple($seq)       => $opt,
    t_tuple($seq, $any) => $any,
);
sig('Seq::contains',   $seq, $any,               $bool);
sigt('Seq::to_array',  t_tuplen(1, $seq, $int), $array);
sigt('Seq::index',
    t_tuple($seq, $int)       => $opt,
    t_tuple($seq, $int, $any) => $any,
);
sig('Seq::to_arrays',  $any, $any);
sig('Seq::to_seq',     $seq, $seq);
#sig('Seq::expand',    $seq, ...);
sig('Seq::length',     $seq,                       $int);
sig('Seq::sum',        $seq,                       $num);
sig('Seq::sum_by',     $seq, $sub,                 $num);
sigt('Seq::min',
    t_tuple($seq)       => t_opt($num),
    t_tuple($seq, $num) => $num,
);
sig('Seq::min_by',     $seq, $sub,                 $opt);
sig('Seq::min_str',    $seq,                       t_opt($str));
sig('Seq::min_str_by', $seq, $sub,                 $opt);
sigt('Seq::max',
    t_tuple($seq)       => t_opt($num),
    t_tuple($seq, $num) => $num,
);
sig('Seq::max_by',     $seq, $sub,                 $opt);
sig('Seq::max_str',    $seq,                       t_opt($str));
sig('Seq::max_str_by', $seq, $sub,                 $opt);
sigt('Seq::join',      t_tuplen(1, $seq, $str),    $str);
sig('Seq::split',      $seq, $regex,               $seq);
sig('Seq::as_hash',    $seq,                       $hash);
sig('Seq::to_hash',    $seq, $sub,                 $hash);
sig('Seq::to_hash_of_array',  $seq, $sub,          $hoa);
sig('Seq::to_array_of_array', $seq,                $aoa);
sig('Seq::find',       $seq, $sub,                 $opt);
sig('Seq::any',        $seq, $sub,                 $bool);
sig('Seq::all',        $seq, $sub,                 $bool);
sig('Seq::none',       $seq, $sub,                 $bool);
sig('Seq::pick',       $seq, $sub,                 $opt);
sig('Seq::count',      $seq,                       t_hash(t_of $int));
sig('Seq::count_by',   $seq, $sub,                 t_hash(t_of $int));
sig('Seq::intersect',  $seq, $seq, $sub,           $array);


###---------------
### QUEUE
###---------------

my $queue = t_ref('Queue');

sigt('Queue::new',        t_tuplev($any, $array),    $queue);
sig ('Queue::length',     $queue,                      $int);
sigt('Queue::add',        t_tuplev($queue, $array),   $void);
sig ('Queue::to_array',   $queue,                    $array);
# list context
# sigt('Queue::remove',
#     t_or(
#         t_tuple($queue),
#         t_tuple($queue, t_int)
#     ),
#     t_array
# );

###----------------------------
### HEAP
###----------------------------

my $heap = t_ref('Heap');

sig ('Heap::new',        $any, $sub,                $heap);
sig ('Heap::count',      $heap,                      $int);
sigt('Heap::add',        t_tuplev($heap, t_array),  $void);
sig ('Heap::add_one',    $heap, $any,               $void);
sig ('Heap::head',       $heap,                      $any);
sig ('Heap::remove',     $heap,                      $any);
# sig ('Heap::remove_all', $heap,                     t_any); # list context
sigt('Heap::show_tree',  t_tuplen(1, $heap, $sub),  $void);

###----------------------------------------
### Equality
###----------------------------------------

sig('Sq::Equality::add_equality', $str, $sub, $void);

1;
