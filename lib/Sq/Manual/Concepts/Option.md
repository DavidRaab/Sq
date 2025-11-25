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

# Nested Options

You can nest options in any depth, but they are automcatically flatted.

```perl
# Same as: Some(1,2,3,4,5,6,7,8)
my $opt = Some(
    1,2,3,
    Some(4,5,6),
    Some(7,Some(8))
);
```

But as soon there is some `undef` or `None` in it, everything evaluates to
`None`.

```perl
# Same as: None
my $opt = Some(
    1,2,3,
    Some(4,None,6),
    Some(7,Some(8))
);
```

you theoretically can use this feature for example to wrap multiple function
outputs in a `Some`, and only when all three returned some valid value the
whole result is successfull.

```perl
my $all_valid = Some(
    function1(),
    function2(),
    function3(),
);
```

the nesting has some kind of *compatiblity* layer in it. The advantage of this
behaviour is that you always can wrap a `Some()` around another option, and
you never get an option of an option.

In a language like F#, and maybe other there it might be possible to create this,
but i decided that this makes no sense. Technically an option of an option
means the whole state of the option just depends on the most inner value.
The compatibility that this creates is the following. Look at this code.

```perl
my $opt = Some(function());
```

Now the return value of `function()` will be wrapped in an optional. But the
interesting thing is that `function()` can return a normale value/undef or
decide to return an `Option` type. No matter what it returns, `$opt` will
just be a single Option representing the output.

This feature can be used and is especially useful for lambda functions.

# Array::pick

For example `Array::pick` is a function that tries to find a variable in an
Array. But also combines a `map` in one operation. You simply pass a function
to it. And as soon it returns `Some($value)` the value is used, while `None`
values are skipped.

Because in the implementation I also basically wrap the result of the lambda
in a `Some()` call, you now can return both an `Option` or still use `undef`.

```perl
my $opt = Array->range(1,10)->pick(sub($x) { $x % 2 == 0 ? Some($x*$x) : None  });
my $opt = Array->range(1,10)->pick(sub($x) { $x % 2 == 0 ?      $x*$x  : undef });
```

Both work and will give you `Some(4)` as a result.

This gives you the flexibility to use functions that do not return an `Option`
without the need to explcitiy call `Some()` in the lambda, but also to
upgrade your own function and switch to an `Option` without changing code
at every place.

# match, map, iter

The most used function are probably `match`, `map` and `iter`.

`match` is a function that allows you to extract the value of an `Option` and
also do some additional computation on it. You use that function when you want
to decide and check if you either get `Some($value)` or `None`. Typical usage
looks like this.

```perl
# 20
my $double = Some(10)->match(
    Some = sub($x) { $x * $x },
    None = sub     { 0       },
);

# 0
my $double = None->match(
    Some = sub($x) { $x * $x },
    None = sub     { 0       },
);
```

`match` extracts the value, so after a `match` you don't have an `Option` value
anymore. But because of this you must provide a function for both cases.
Sometimes you are just interested to execute some code when you got `Some($value)`
and do nothing at all when you got `None`. In this case you use `map`.

```perl
my $opt = Some(10)->map(sub($x) { $x * $x }); # Some(20)
my $opt =     None->map(sub($x) { $x * $x }); # None
```

`match` and `map` are both functions to give you a new value. Sometimes you
just want to execute some code when you got `Some($value)`, do something,
for example a side-effect (like printig) or do nothing at all. You are also
not interested in a new value. In that case you use `iter`.

```perl
Some(10)->iter(sub($x) { printf "Got Number: %f\n", $x }); # printf will be excuted
    None->iter(sub($x) { printf "Got Number: %f\n", $x }); # nothing will happen
```

# map2, map3, map4, map_v

`map2` is a function that you use, when you want to unpack two options
and when they are some value, want to execute some code with those values in
it.

```perl
my $optA = Some(8);
my $optB = Some(7);
my $optC = None;
my $mul  = sub($x,$y) { $x * $y };

my $optD = Option::map2($optA, $optB, $mul); # Some(56)
my $optE = Option::map2($optB, $optC, $mul); # None
```

Often when working with `map`, `map2`, ... we focus too much on the data. As a Perl
developer you are probably used to think `map` is just about creating a new Array.

But the concept comes from functional programming that is more focused about
the function instead of the data. You can have many `map` functions for different
data-types. Sq ships with `map` functions for *Array*, *Hash*, *Seq*, *Option*
and *Result*.

Better is to think about the function instead. In this example `$mul`. `$mul`
is a function that don't know about `Option` type. It also don't know about
`Array`, `Seq` or `Result`. But with those `map` functions you can make
`$mul` operate on those types. For example you can re-use `$mul`.

```perl
# array(Some(56), None)
my $arrayMul =
    Array::map2(
        [Some(8), Some(8)],
        [Some(7), None],
        $mul
    );

my $resultMulA = Result::map2(Ok(8), Ok(7),        $mul); # Ok(56)
my $resultMulB = Result::map2(Ok(8), Err("error"), $mul); # Err("error")
```

Consider it the other way around. With `Array::map2` it is like that `$mul` get
enhanced, and it's function arguments now supports being Arrays. With `Result::map2`
you can enhance `$mul` and it's arguments now can be `Result` types, without
that you need to write code yourself to somehow extract, iterate and do some
other stuff to make it compatible, depending on the data-type.

In functional programming, a data-type that supports a `map` function is also
named a **Functor**.

Not very difficult at all, but sometimes people are scared of unknown names.
I assume you know also could guess what a

```perl
my $asyncC = Async::map2($asyncA, $asyncB, $mul);
```

would do? Or

```perl
my $bananaC = Banana::map2($bananaA, $bananaB, $mul);
```

`map3` and `map4` just does the same for three or four arguments. When you need
more than four arguments, you should use `map_v`. The `v` is for *variable*.
You can pass as many *Options* you want, only the last one must be a *function*.

Just as an extended example. You could for example implement `map2` yourself
with `match`.

```perl
sub map2($optA, $optB, $f) {
    $optA->match(
        None => sub { None },
        Some => sub($a) {
            $optB->match(
                None => sub { None },
                Some => sub($b) {
                    Some($a * $b);
                }
            )
        }
    );
}

# Signature with Sq::Signature
sig('map2', t_opt, t_opt, t_sub, t_opt);
```

# bind

TODO

# or, or_with, or_else, or_else_with

TODO

# Array::all_some

TODO

# Option->extract()

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
