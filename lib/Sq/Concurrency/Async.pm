package Sq::Concurrency::Async;
use 5.036;

# An async implementation. Is maybe one of the last modules i probably
# will implement. Because Perl has no Threading support it would just
# be a non-blocking asnychronous event loop.
#
# But do we really need another implementation?
#
# I like AnyEvent a lot. So maybe this will just be an interface that
# connects AnyEvent with Sq and leaves the whole implementation of
# the Async Queue to AnyEvent. That also has great performance and
# is written in C.

1;