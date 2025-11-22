# Option

The idea of an option is to replace `undef`. Instead of functions that
return `undef` as values, usually for indicating errors. You better return
an `Option` instead.

An `Option` is still a value that has functions to work with that help you
to write code that is correct.

# The Problem

TODO: Copy from Overview

# Creation

By default `Sq` export the function `Some()` and `None()` to create those
values. `None` expects no value and has a prototype added, so you usually
always can avoid writing parenthesis.

`Some()` is a little bit different to the usual implementation you see
in other languages. First of. The function supports multiple values.

Sou you can write `Some(1)` but also `Some(1,2,3)`. Some sure allows
every value, so you also can write `Some([1,2,3])`.

A special case is when `undef` or no value at all is passed. Because the
whole point is to avoid `undef` in `Sq`. An `undef` automatically turns
into `None`.

This is very handy, as you usually can wrap any function call that uses
`undef` or an empty list as an error mechanism and wrap an `Some` around it.

```perl
my $opt = Some(stat 'file');
```

For example the above will either be Some values containing a list, or
either be `None`. In that case it also makes sense to combine it with the
`record()` function. `record()` turns a list of values into a hash. It
just expects the hash fields in order, and returns a function.

```perl
my $to_hash = record(qw/dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks/);
my $opt     = Some(stat 'file')->map($to_hash);
```

For performance you can for example save the `$to_hash` in a `state` variable.
Otherwise you also can write it inline.

```perl
my $opt =
    Some(stat 'file')
    ->map(record(qw/dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks/));
```

Now `$opt` is either `Some($stat_hash)` or `None`.

# match

TODO

# Nested Options

TODO

# Use Case 1

In C or some other languages you sometimes see a function like that.

```c
Hit hit;
if ( intersect(this, that, &hit) ) {
    // Do something with hit
}
```

The idea is as following. The `intersect` function returns a boolean
value indicating success or not. But it also should return a `Hit`. But
this is not possible. The solution many languages pick is by passing a
reference/pointer to the function call that can write it's result into
it. Here `&hit`.

This means whoever is calling `intersect` must initiliaze a variable/memory
and pass that to the function.

An `Option` type makes this scenario better. In `Sq` a function could look
like this instead.

```perl
intersect($this, $that)->iter(sub($hit) {
    # Do something with $hit
});
```

`intersect()` now returns an option. Either you get `Some($hit)` or `None`.
The `->iter` is another function that is used for side-effects. It only
executes the passed function when ther was `Some($value)`.

An `Option` can represent two things at once. A success/failure including
any arbitary value with a success.

# Use Case 2

Options are used itself in `Sq`. For example you can `map` and `grep` a list
in Perl.

```perl
my @result =
    grep { $_ % 2 == 0 }
    map  { $_ * 2      } 1 .. 10;
```

With Sq, you can write.

```perl
my $result =
    Array
    ->range(1,10)
    ->map( sub($x) { $x * 2      })
    ->keep(sub($x) { $x % 2 == 0 });
```

both cases nearly do the same. But `Sq` returns a blessed Array-ref instead
of a list, and the order is swaped. But both have the problem that an
intermediate list is created. Instead you can use `pick()` that combines
both operations into one. `pick` expects that you return an Option.

```perl
my $result =
    Array
    ->range(1,10)
    ->pick(sub($x) {
        my $double = $x * 2;
        return $double % 2 == 0 ? Some($double) : None;
    });
```

This does the transformation and filtering in one step. You also can
write functions that uses Option this way.

Otherwise also using a `Seq` can be a better approach.

```perl
my $result =
    Seq
    ->range(1,10)
    ->map( sub($x) { $x * 2 })
    ->keep(sub($x) { $x % 2 == 0 })
    ->to_array;
```

`Seq` also has a `pick` function you could use. But even when you write
it the above way. No full intermediate array has to be created. In practice
however, you also should try to avoid using `to_array`.

When you just want to iterate all values just use `->iter()` and so on.
From C# Linq i have a lot of experience that people to often call `ToArray`
or `ToList` just to iterate it afterwards with a foreach. Don't do that.
Just iterate!

```perl
# don't do this

my $array = $seq->to_array;
for my $x ( @$array ) {
    # do something with $x
}

# do this instead

$seq->iter(sub($x) {
    # do something with $x
});
```

One advantage of using `iter` is also that it works with an Array or a Seq!

# Use Case 3

Because Perl data-structures are dynamically typed, you for example have
no restriction that some keys on a hash must exists or not. When working
with data, it is often easier when all keys are always some kind of value.

For example assume you want a hash containing an `id`, `name` and a `points`.
You could use the `record` function for easier creation of data.

```perl
# this creates a "data" function from the returned function of record()
fn data => record(qw/id name points/);

my $a = data(1, "Zelda", 0);
my $b = data(2, "Mario", 0);
my $c = data(3, "Link",  0);
```

But `record` creates a function always expecting the exact amount of values.
Now consider `points` should be optional. Optional means no value is
provided. Providing `0` as a value is not the same as the idea of *No Value*.

Usually you either would create a hash without the `points` field. Either
use `undef` or the functional approach is to expect an optional value
instead.

```perl
# this creates a "data" function from the returned function of record()
fn data => record(qw/id name points/);

my $a = data(1, "Zelda", None);
my $b = data(2, "Mario", None);
my $c = data(3, "Link",  Some(20));
```

the type of this Hash would be

```perl
my $is_data = type [hash => [keys => [
    id     => ['num'],
    name   => ['str'],
    points => [opt => ['num']],
]]];
```

The advanatage is that you always can access `->{points}` and always get a
an Option value that you can somehow work with.

```perl
my $point_str = $data->{points}->match(
    Some => sub($p) { sprintf "Points: %d", $p },
    None => sub     { sprintf "No Points"      },
);
```
