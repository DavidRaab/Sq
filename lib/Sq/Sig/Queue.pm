package Sq::Sig::Queue;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

my $queue = t_ref('Queue');

sigt('Queue::new',        t_tuplev(t_any, t_array),  $queue);
sig ('Queue::capacity',   $queue,                     t_int);
sig ('Queue::count',      $queue,                     t_int);
sig ('Queue::add_one',    $queue, t_any,             $queue);
sigt('Queue::add',        t_tuplev($queue, t_array), $queue);
sig ('Queue::remove_one', $queue,                     t_any);
# list context
# sigt('Queue::remove',
#     t_or(
#         t_tuple($queue),
#         t_tuple($queue, t_int)
#     ),
#     t_array
# );
sig ('Queue::raise',    $queue,        t_void);
sig ('Queue::iter',     $queue, t_sub, t_void);
sig ('Queue::iteri',    $queue, t_sub, t_void);
sig ('Queue::foreach',  $queue, t_sub, t_void);
sig ('Queue::foreachi', $queue, t_sub, t_void);
sig ('Queue::to_array', $queue,       t_array);

1;