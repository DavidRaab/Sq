=head1 Immutability

Here is what I think about Immutability.

The first time i came into contact with immutability was while learning
Moose as soon it came out. I used it immediately when it came out. There
I learned about immutability and to make objects 'read-only'.

At first, i didn't understand the concept. How can you compute something
without changing anything?

I mean, even for a simple loop you need a way to change a value, or not?

Later I understood the concept better. It's more about creating new things,
creating new data instead of trying to change the current state.

The whole point of immutability in itself is actually lesser important.

In fact, Perl developers should knew well. We have functions like C<map>,
C<grep> and C<sort> built-in, and all of those create new arrays instead of
manipulating an existing one. But the result is still mutable.

And still, i never runned into real performance issues in Perl, even in that
"slow" language. Sure, still depends sometimes what you are doing.

