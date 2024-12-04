=head1 Option->extract_array(...)

Here i wanna describe in more detail why those functions exists, what they
do, and more important, why they are how they are. I guess by understanding
what leads to the development of this function it shows more insight how to use
Option in Sq and what you can do.

=head1 Some() at the beginning

At the beginning C<Some> returned a valid value for every value, except
for C<undef>. This behaviour is somehow nice as you can wrap the result of
any function into C<Some> and always get an option back. You just can write.

    my $opt = Some( func() );

This is very convenient because there are a lot of Perl functions throught Perl
in a lot of modules that indicate an error. So turning any non option aware
function into an option aware is pretty straightforward.

But the idea in C<Sq> is that C<Option> should be used. Let's say someone
upgrade its C<func()> function and now starting to return C<Option>. Now
that code doesn't work anymore.

=head1 Some() detects Option

It didn't worked because C<Some> when C<func()> returns an C<Option> and now
you wrap it again in C<Some> you suddenly got a C<Some(Some($value))> or maybe
a C<Some(None)>.

At this point I thought about the idea if wrapping C<Option> anyway makes sense.

I came to the conclusion it didn't. Values like C<Some(Some(Some(10)))> have no
additional information compared to C<Some(10)>. So I changed C<Some> that it
detects for an optional. Now we still can write.

    my $opt = Some( func() );

but C<func()> is free to decide if it either return a C<value/undef> or returns
C<Some/None> and it just works. C<$opt> will now always be just a single C<Option>,
nothing wrapped and you can work with it.

=head1 Option->extract

This brought me to the implementation of

    my ($is_some, $x) = Option->extract( func() );

So here is the idea. While the above works fine it can have a performance impact.
Because always an C<Option> value must be created. But let's say that you just
want to check if we had a valid value or not, and just want to get the value.
We don't need to return an C<Option> besides that don't call any methods on
it. So creating an C<Option> seems a waste when C<func()> returns a
normal C<valid value> or C<undef>.

We could optimize that by calling C<func()> and then check the return value.
When it is an C<Option> we just work with it. If not we just use the value
and check for C<defined> instead.

And this is exactly what C<< Option->extract >> does. So you/me don't have
to implement this again and again.

C<< Option->extract >> is somehow similar to C<Go> language as now it returns
two variables. The first one indicating if we had a valid value, and the second
variable is the actual value.

The pattern is usually

    my ($is_some, $x) = Option->extract(func());
    if ( $is_some ) {
        # do something with x
    }

    my ($is_some, $x) = Option->extract(undef);    # 0
    my ($is_some, $x) = Option->extract(None);     # 0
    my ($is_some, $x) = Option->extract(10);       # 1, 10
    my ($is_some, $x) = Option->extract(Some(10)); # 1, 10

C<< Option->extract >> works bei either unpacking the option or it does
a C<defined> check for you. This means it unifies two different syntaxes
and ideas about an empty value and it will just work. In the case when
C<func()> does not return an C<Option> it is a little bit faster as no C<Option>
must be created.

=head2 Option->extract_array()

This leads to the next function. Because Perl also allows to return multiple
values instead of just one single value. And at some places this feature
was used.

For example in C<< Array->unfold >> you pass a lambda that should return
two values. The C<$x> value used in the array and C<$state> for the next
state to build the next value.

Here returning the B<empty list> or C<undef> was used to decide if we want
to abort the generation. But wouldn't it be nice it also could work
with C<Option>? Because this differentation between a valid value or not
is exactly what C<Option> is all about.

But C<Option> is limited to only a single value. So how do we return multiple
ones? Well by wrapping it in an array.

    my ($is_some, @xs) = Option->extract_array();             # 0
    my ($is_some, @xs) = Option->extract_array(undef);        # 0
    my ($is_some, @xs) = Option->extract_array(None);         # 0
    my ($is_some, @xs) = Option->extract_array(5,10);         # 1,5,10
    my ($is_some, @xs) = Option->extract_array(Some([5,10])); # 1,5,10
    my ($is_some, @xs) = Option->extract_array(10)            # 1,10

At first I always expected that a user must pass an array to Some C<Some([10])>
but why create an array when we anyway only have a single value? Instead
I also allowed that a single value can be passed.

So it is very like a DWIM (Do What I Mean) function. A user can return no
value at all by an empty C<return> a single C<undef> or C<None> and
all of them will turn into C<$is_some> being C<0>.

Then you can decide to return C<Some($value)> for a single value or return
C<Some([$x,$x,$x])> and return multiple values. And you don't have to write
the whole type-checking conditional logic yourself.
