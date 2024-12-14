package Sq::Control::Event;
use 5.036;

# An Event like structure. With an Event you can subscribe and
# unsubscribe. The idea is also to have stuff like map, filter, choose
# and all the other stuff of function you see in Seq, Array.
# Sometimes also called Observable. Also named "Reactive Programming",
# Reactive Streams, or just "Rx".
#
# But i don't like working with Events. After working with a lot of
# Event stuff i think Events are horrible. They seem nice and easy.
#
# But when used heavily you completely lose the ability to know what
# happens in your program. There is no clear execution path anymore.
# Horrible tu understand or debug. Slow.

1;