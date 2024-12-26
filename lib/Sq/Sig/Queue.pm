package Sq::Sig::Queue;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

my $queue = t_ref('Queue');

sigt('Queue::new',        t_tuplev(t_any, t_array),  $queue);
sig ('Queue::length',     $queue,                     t_int);
sigt('Queue::add',        t_tuplev($queue, t_array), t_void);
sig ('Queue::to_array',   $queue,                   t_array);
# list context
# sigt('Queue::remove',
#     t_or(
#         t_tuple($queue),
#         t_tuple($queue, t_int)
#     ),
#     t_array
# );

1;