=head1 Sequence or Array

What is the point of a sequence anyway, why you might wanna use it,
and in which cases you don't want to use? Let my try to explain.

=head2 Reading a file

Let's say we wanna read a file from disk. We assume it is maybe in a format
like CSV, or could be any other format. Line based, maybe it is byte based.
The format itself doesn't matter, but for processing you decide.

=over 4

=item Read the whole file into memory

=item Do a computation/transformation on every entry

=item Maybe do some kind of accumulation

=back

In pure Perl, code could somehow look like this.

    use File::Slurp;

    my @file_content = read_file('...');
    my @transform =
        grep { ... }
        map  { ... }
            @file_content;

    my $accum = ...;
    for my $t ( @transform ) {
        # do something with $accum
    }

This kind of code works but this kind of code can have some serious
drawbacks.

=over 4

=item Memory consumption

The whole file needs to be read into memory. When you have a relative small
file this is maybe fine. But when you need to process very big amount of
data. Maybe files with several gigabytes of size, or data from a database
this approach can fail.

=item Execution Order

I consider this less of an issue as i am used to it now, but still sometimes
it is annoying that the order of C<grep> and C<map> is swapped. The code
first C<map> some data, and then it does C<grep> for filtering. Still the
order we write or read is reversed. Sometimes i like this order better,
sometimes not.

=item Inefficent

This code also can become inefficent for the CPU. Even though today we have SSD
or NVME and disk throughput and access time has greatly improved, from the
perspective of a CPU it is usually still waiting for data.

This means that reading a whole file into memory will probably just cause 1%
of CPU usage and the processor will likely spin 99% idling doing nothing
and waiting for data to arrive into memory.

Once all data are loaded into memory and accessible in the array, computing
becomes very fast. But the overall speed of your program still can be slower
because you still spent most time reading a file and waiting without
your CPU doing anything.

=back

=head2 Sq Array

Now let's assume we rewrite the pure perl code we have so far using Array.
Because we still use C<Array> it will still have the same disadvantages.
But let's see how it will look using Sq.

    use Sq;
    use File::Slurp;

    my $file_content = Array->bless([read_file('...')]);
    my $accum =
        $file_content
            ->map(   sub($x) { ... })
            ->filter(sub($x) { ... })
            ->fold($state, sub($t,$state) {
                # do something with $t & $state
            });

=over 4

=item Execution Order

One thing that changed is the order in which we write our code. Now it becomes
clear that we first C<map> every entry of an array. Then we C<filter> out
some elements and finally do a C<fold> that transforms a whole array into
something different.

=item More functions

Perl itself only provides C<map> and C<grep> as functions operating on
Arrays, but the C<Array> module shipped with C<Sq> will have around 100
of common Array transformations you can use. Those are common problems
you either have to write again and again in Perl yourself, or you just
use C<Sq>.

=item Code readability

Accessing transformations by a name also makes code better understandable.
Without such pre-defined functions all you do is basically always again and
again traversing arrays with a C<for> loop usually to transform your data.

But the reader has to decipher the meaning of a C<for> loop. For example
calling C<min> on an Array will be much more better understandable as
trying to understand the C<for> loop that tries to implement the
selection of a minimum value.

=item Speed & Performance

When we talk about this topic very often people only care for the performance
in the sense of how much CPU time something take. But programming is not all
about the CPU. As a human I also care how much time I need to write and come
up with a correct solution that works.

Using C<Sq> can be faster as you just can access a library of common
data-transformations, but this library heavily depends on the usage of
anonymous functions and calling functions. In today age it seems that the
cost of just calling a function is sometimes underestimated. Every
function call needs to push values onto a stack, needs jump instructions
and so on. Calling functions can become a serious overhead, especially when
we have code in loops and process/iterate millions of items.

=item No forced paradigma

But consider the following thing. C<Sq> does not try to enforce a paradigm on
you, it tries to teach you just another paradigm that you maybe like because
of it's advantages.

You can start using C<Sq>, create code that is fast written for you, does
what it should do and is maybe fast enough. If not, you maybe can Profile your
code and always create the Pure Perl versions of those operations that
needs to be faster because they are critical.

=back

=head2 Line based Code

Now let's B<fix> the problems we have with the first original pure Perl version.
Instead of reading a whole file into memory we go through everything line based.
Let's compare how the code changes.

We started with the following code.

    use File::Slurp;

    my @file_content = read_file('...');
    my @transform =
        grep { ... }
        map  { ... }
            @file_content;

    my $accum = ...;
    for my $t ( @transform ) {
        # do something with $accum
    }

now we want to iterate line by line and do the transformation, filtering
and creating of $accum as efficent as possible. Now we have code like this.

    my $fh = open my $fh, '<', '...';

    my $accum = ...;
    while ( my $line = <$fh> ) {
        # this is basically the map call
        my $transform = transform($line);

        # this is basically grep
        if ( $transform ... ) {
            # do something with $transform + $accum
        }
    }

This kind of code B<fixes> the problem we had with the first solution. That
means.

=over 4

=item Just line based

Instead of reading the whole file into memory we just process it line by line.
We could easily process a 10 GiG file this way. It completely depends on
C<$accum> and what we create here and how big that data is if our process fails
or not. But consider in the first version we would need the whole file into
memory + C<$accum>. In this solution it is just C<$accum> + 1 line.

=item Execution Order

Execution Order is now in order, we first see that we transform, then we filter.
But still this code suffers from what i have deescribed above about C<for>
loops being hard to read. It becomes a lot harder to decipher as a human
reading code what our C<while> loop actually does.

=item Efficent

This code can be a lot more efficent, especially when we read something from
a file. Instead that the processor now waits a lot of time for data
to arrive, we immediately execute some code and create/process data to
create C<$accum> instead of just waiting for data to arrive.

Reading something line based, then doing something with it is a great way
to speed up all kind of I/O processing, because in the meantime our code
already process data our operating system is not sleeping.

In the background different kind of IO Layers back down to the operating
system will fill buffers, so the overal time our program needs to run will
very likely become less. The waiting time is used to compute things instead of
idling our processor.

=back

But you know what I didn't liked at all? It's how different we need to write
code. I like writing code with C<map> and C<grep> and some kind of helper
functions from List::Util and so on. But when we need to write code that
cannot read everything into memory at once than we cannot use those functions.

Then suddenly we have to unroll all those functions and write code that
looks like primitive C code.

Now let's look what happens when we replace it with C<Seq>.

=head2 Sequence based solution

Again, let's start with the Sq Array solution. We had the following code.

    use Sq;
    use File::Slurp;

    my $file_content = Array->bless([read_file('...')]);
    my $accum =
        $file_content
            ->map(   sub($x) { ... })
            ->filter(sub($x) { ... })
            ->fold($state, sub($t,$state) {
                # do something with $t & $state
            });

And now here is the sequence based solution that don't need to read everything
into memory all at once.

    use Sq;

    my $file_content = Sq->io->open_text('...');
    my $accum =
        $file_content
            ->map(   sub($x) { ... })
            ->filter(sub($x) { ... })
            ->fold($state, sub($t,$state) {
                # do something with $t & $state
            });

So what changed? Well not much. C<< Sq->io->open_text >> returns a sequence
that iterates line by line through a file. But C<Seq> has the same API
as C<Array>. So the code looks exactly the same, but it has all the benefits
of the B<Line Based Code>.

It might be correct that C<Seq> has some overhead and all that lambda calling
makes it slower. But this is only compared to an C<Array>. When we use C<Seq>
on a file, socket or any other kind of B<Slow IO> then we just trade a little
bit more CPU consumption.

But this is totally fine. The purpose of CPUs is to compute things, not idling
around doing nothing.

=head2 What if Seq is not fast enough?

Well than you have to unroll the Seq code into pure perl code and try to
eleminate any function calling. That's how you speed up everything as much
as possible in Perl.

But i consider that using C<Seq> or C<Sq> in general will help you to write
code faster, still get a performance gain in most scenarios and transition
between different versions are easier. Like switching from C<Array> to C<Seq>.

When something is not fast enough you can Profile your code. Look at
L<Devel::NYTProf> for this. And then just unroll the C<Seq> or C<Array> code
into pure perl.

But it helps having code written with C<Seq> or C<Array> and then turn it into
a series of single steps. Especially when you have a test-suite, tested your
abstract code and then re-write some functions for speed.
