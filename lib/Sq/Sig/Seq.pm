package Sq::Sig::Seq;
use 5.036;
use Sq::Type;
use Sq::Signature;

# Some predefined types
my $any  = t_any;
my $seq  = t_seq;
my $sub  = t_sub;
my $opt  = t_opt;
my $aos  = t_array(t_of $seq);
my $hoa  = t_hash (t_of t_array);
my $aoa  = t_array(t_of t_array);

### CONSTRUCTORS

sig ('Seq::from_sub',   $any,  $sub,               $seq);
sig ('Seq::always',     $any, $any,                $seq);
sig ('Seq::empty',      $any,                      $seq);
sig ('Seq::replicate',  $any, t_int, $any,         $seq);
sig ('Seq::unfold',     $any, $any,  $sub,         $seq);
sig ('Seq::init',       $any, t_int,  $sub,        $seq);
sig ('Seq::range_step', $any, t_num, t_num, t_num, $seq);
sigt('Seq::new',        t_tuplev($any, t_array),   $seq);
sig ('Seq::range',      $any, t_int, t_int,        $seq);
sig ('Seq::from_array', $any, t_array,             $seq);
sig ('Seq::from_hash',  $any, t_hash,  $sub,       $seq);
sigt('Seq::concat',     t_tuplev($any, $aos),      $seq);
sig ('Seq::up',         $any, t_int,               $seq);
sig ('Seq::down',       $any, t_int,               $seq);

### METHODS

sig('Seq::copy',          $seq,                 $seq);
sig('Seq::append',        $seq, $seq,           $seq);
sig('Seq::map',           $seq, $sub,           $seq);
sig('Seq::map2',          $seq, $seq, $sub,     $seq);
sig('Seq::bind',          $seq, $sub,           $seq);
sig('Seq::flatten',       $seq,                 $seq);
sig('Seq::merge',         $seq,                 $seq);
sig('Seq::cartesian',     $seq, $seq,           $seq);
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
sig('Seq::rxs',           $seq, t_regex, t_sub, $seq);
sig('Seq::rxsg',          $seq, t_regex, t_sub, $seq);
sig('Seq::chunked',       $seq, t_int,          $seq);
sig('Seq::windowed',      $seq, t_int,          $seq);
sig('Seq::intersperse',   $seq, $any,           $seq);
sig('Seq::infinity',      $seq,                 $seq);
sig('Seq::repeat',        $seq, t_int,          $seq);
sig('Seq::trim',          $seq,                 $seq);

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

sig('Seq::sort',       $seq, $sub,            t_array);
sig('Seq::sort_by',    $seq, $sub, $sub,      t_array);
sig('Seq::group_fold', $seq, $sub, $sub, $sub, t_hash);
sig('Seq::group_by',   $seq, $sub,               $hoa);
sig('Seq::fold',       $seq, $any, $sub,         $any);
sig('Seq::fold_mut',   $seq, $any, $sub,         $any);
sig('Seq::reduce',     $seq, $sub,               $opt);
sig('Seq::first',      $seq,                     $opt);
sig('Seq::last',       $seq,                     $opt);
sigt('Seq::to_array',
    t_or(
        t_tuple($seq),
        t_tuple($seq, t_int),
    ),
    t_array
);
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
sig('Seq::join',       $seq, t_str,                t_str);
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