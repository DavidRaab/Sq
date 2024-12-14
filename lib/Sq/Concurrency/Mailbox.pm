package Sq::Concurrency::Mailbox;
use 5.036;

# F# Mailboxes are cool. They are basically a concurrent Queue with mutable
# state. The only thing you can do is send messages to it. Basically a
# leightweight Actor Model / Smalltalk system.
#
# But Perl has no real Thread implementation. So don't know if this ever
# will happen :(

1;