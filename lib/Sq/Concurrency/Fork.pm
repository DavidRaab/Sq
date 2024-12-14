package Sq::Concurrency::Fork;
use 5.036;

# The only real thing Perl has is calling fork(). At least under Unix
# like systems it works. A typical mechanism for working with
# fork() is by creating a Pipe and then create channels so processes
# can talk with each other.
#
# This is different to Threads that can share data. With fork you
# must serialize data, send them and the receiver must de-seralize
# the data. Basically the same how all Network internet protocols work.
#
# Every Web Server works by sending data (HTTP Request) and it answer
# with a (HTTP Response) and they are just data.
#
# The idea of Sq is to just work with plain data-structures. So i hope
# you can see why this model would work fine with Sq.

1;