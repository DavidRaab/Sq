package Sq::Sig::Heap;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

my $heap = t_ref('Heap');

sig ('Heap::new',        t_any, t_sub,              $heap);
sig ('Heap::count',      $heap,                     t_int);
sigt('Heap::add',        t_tuplev($heap, t_array), t_void);
sig ('Heap::add_one',    $heap, t_any,             t_void);
sig ('Heap::head',       $heap,                     t_any);
sig ('Heap::remove',     $heap,                     t_any);
# sig ('Heap::remove_all', $heap,                     t_any); # list context
sigt('Heap::show_tree',
    t_or(
        t_tuple($heap),
        t_tuple($heap, t_sub)
    ),
    t_void
);

1;