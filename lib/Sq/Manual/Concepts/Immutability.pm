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

=head2 Easy example

An easy example to understand Immutability is to understand

    my $x = 10;
    my $y = 5;
    my $result = $x + $y;

Here we also wouldn't expect that adding C<$x + $y> changes C<$x> or C<$y>.
They stay the same. This is what you can do with every operation!

And still, i can do.

    $x = 20;

But consider that this is more changing the variable. Here C<$x> is just a named
slot in your computer memory. And this slot can change. But the value C<20>
still stays the same.

Consider that C<+> is just a function. Like any other. But most languages
decides to threat some functions more special, so C<+> can be written between
two values. In Lisp for example this is not special. When Perl wouldn't
have decided to make this special it would just look like this.

    my $result = +($x, $y);

Nothing different to any other function call with a name.

    my $result = fold($x, $y);

=head2 Pure Functions

In functional programming there is the concept of B<Pure Functions>. A function
is condered B<Pure> when a function always returns the same values for the same
input. And it never changes its input values, or does some other effect like
printing, writing, usually everything that is considered as IO (Input-Output).

But it doesn't matter if the values it receives or returns are mutable.

A function that get's a mutable array, but never changes that mutable array
and returns something new, is a completely pure function.

Immutable data-structures forces you to write pure functions, but still doesn't
mean you cannot do that with mutable data-structures.

=head2 Cache / Memoize

Caching as a side-effect. Describe why a cached function is still B<Pure>.

=head2 Hash is a function

Data as a function. A function with a single input and a single output can
be cached in a Hash. It's a simple key to value mapping.

The problem is that we don't have enough memory for this.

=head2 Recursion

Describe a loop with recursion.

=head2 Loop

Describe how it get's transformed during compilation.

=head2 Recursion to Iteration

Describe How every recursive function can be transformed into an iterative loop.

=head2 Costs/Benefits of immutability

=head2 Chaining

When immutable data only is consumed by a single output to input
function than the whole change of operations could be done
on a mutable data-structure.

=head2 Owner of data?

Why returning mutable data from a function is completely fine.
