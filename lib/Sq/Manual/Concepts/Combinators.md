# Combinators

*Combinators* is a concept from functional programming. In functional
programming it is normal that also functions can be used like variables.
You can store them in variables or pass them as values. *Combinators*
built on top of this idea by providing functions to combine functions
to build new functions.

As an example I go through the creation of `Sq::Gen` to build a system
to generate random data.

# Functions as interfaces

When you have done some programming in a static-typed OO language you probably
know interfaces. An interface is a description of which attributes and methods
a class should implement. But not just the name, also it's input and output
parameters.

For example you could create the following interface in an OO language (C#)

```csharp
public interface IGenerator {
    public Out Invoke(In whatever)
}
```

this interface defines a single function that takes an `In` as Input and
`Out` as Output parameter. In a functional ML-Like language (ML, F#, Haskell)
you just write:

```fsharp
In -> Out
```

that means the same. The `->` donates a function. On it's left the input, and
on the right the output. You don't need to assign it a name. Every function
with this interface is automatically *compatible*.

Understanding a little bit about typing is important, just because we have a
dynamic-typed language doesn't mean we don't expect data or functions in any
kind format. The format is just not described or checked at compile-time.

# Data Generation without Combinators

First of, let's consider we want to generate a random integer. We want to provide
it a minimum and maximum, and we do it without a Combinator.

In Perl, we could write.

```perl
sub gen_int($min, $max) {
    return int($min + rand($max));
}
```

and then can use it like this.

```perl
my $random_ints = [gen_int(1,10), gen_int(1,10), gen_int(1,10)];
```

this would generate an array with three random ints. Generating Arrays of data
is common, so why not create a function for that too?

```perl
sub gen_array($amount, $min, $max) {
    return [map { gen_int($min,$max) } 1 .. $amount];
}
```

now we could generate random int's array. But maybe you start to see why this
approach is not the best. The problem is that we now have an array generating
function, but it only generates arrays of int. We also must pass `$min` and
`$max` to `gen_array`.

What happens when we want to be able to generate random arrays of strings,
floating numbers, maybe datetime values, or again arrays of arrays, arrays of
hashes and so on. You defenetiely don't want to write a hundreds of possible
functions for every combination that is possible. Is there a way out?

Yes! By expecting functions as arguments. We change `gen_array` to expect
an data-generating function instead. In OO we would say we expect an `IGenerator`
object that we then can call `Invoke()`. In a functional language we
just talk about functions.

Our interface would look like

```fsharp
unit -> 'a
```

This says that we have no input `unit` is like `void` in C-Like languages,
and we get some `'a` back. The tick in front of it makes it a generic type.
So we don't know what type it is. We just say it is some `'a`.

In a dymic-typed language we don't have those types and generic types, but
we also don't need them. But still we must learn that our code and functions
we write share a common interface so they can work together. Our generating
functions in Perl are just functions that take no arguments. And they will
just return one generated value.

# Switching to Combinators

Now we change `gen_int`. Instead of directly return an integer, we let it
return a function, that generates an integer when called. It now looks like
this.

```perl
sub gen_int($min, $max) {
    return sub() {
      return int($min + rand($max));
    };
}
```

The Code actually didn't changed much. We just put the whole function body
in a `return sub() { ... }` so the whole function body is returned again
as a function.

In an OO language for comparision you would write.

```csharp
public class GenInt : IGenerator {
    public Min { get; private set; }
    public Max { get; private set; }

    public GenInt(int min, int max) {
        this.Min = min;
        this.Max = max;
    }

    public int Invoke() {
        return System.Random.Shared.Next(this.min, this.max);
    }
}
```

just in comparison of what it means to return a function as a value. A function
is just like an object with a single method on it, that still has access to
the values in its scope. Here the `$min`, `$max` values.

This whole change of returning functions also means we have todo an additional
step to get an actual value. Now we must do.

```perl
my $fint = gen_int(1,100);
my $int  = $fint->();
```

Pretty much the same as.

```csharp
var gint = new GenInt(1,100);
var vint = gint.Invoke();
```

When we just want to generate integers, then this extra step seems silly, but we don't
want to just generate ints in a range, we wanted to be able to be more flexible
in generating more complex data. Now, we also change the `gen_array` function.

```perl
sub gen_array($amount, $f) {
    return [map { $f->() } 1 .. $amount];
}
```

What now changed is that `gen_array` just expects a function `$f`. We don't
know what this function does. We only know that when we execute it. It get's
some random generated value. This value is just put into the generated array.

Now we are able to write.

```perl
my $int_array1 = gen_array(100,  gen_int(1,100));
my $int_array2 = gen_array(1024, gen_int(0,255));
```

And we have two randomly generated arrays of integers. But we are still not
finished.

How about generating an array of arrays with integers? Well we can't, because
`gen_array()` again generates directly an array and we return it. That's why
when we work with Combinators we always let all functions return just functions.

Or we just say, we stick to our defined interface.

```perl
sub gen_array($amount, $f) {
    return sub {
        return [map { $f->() } 1 .. $amount];
    }
}
```

usually it is best to include some called *Runners*. All our functions return
functions. But instead of directly calling the function we build another function
to execute them.

```perl
sub gen_run($f) {
    return $f->();
}
```

in this case the runner is less useful. But in other cases not. Not every
Combinator is written that it expects no input values. So for example we could
generate some data or structure that then is passed to `$f->($input)`. Also
we could add some things and do whatever `$f` returns. So we can add
something before and after our data is generated.

Now we can write the following.

```perl
# Those just defines what should be generated
my $r1 = gen_array(100,  gen_int(1,100));
my $r2 = gen_array(1024, gen_int(0,255));

# This now really generates the data
my $ints1 = gen_run($r1);
my $ints2 = gen_run($r2);
```

With this last step of change we now also can easily generate arrays of
arrays containing integers.

```perl
# description of array containing 100 arrays containing two integers in range 1-10
my $aoa =
    gen_array(100,
        gen_array(2, gen_int(1,10)));

# this generates the data
my $data = gen_run($aoa);
```

Combinators are a poweful construct that allows you to generate all kind of
things that are very descriptive. It's like an DSL inside your programing
language. In `Sq` itself the type-system `Sq::Type`, `Sq::Parser` and `Sq::Gen`
are written with this approach.

In F# i also have written an Animation-System with this approach. In a
typical Combinator approach it makes sense to implement some kind of *and*
and *or* combinator.

These are functions that usually take multiple combinators (functions) and
combines them into a single function again. For example in this approach
they could look like this.

```perl
# Randomly picks one of @gens
sub gen_or(@gens) {
    my $count = @gens;
    return sub() {
        return $gens[rand $count]->();
    }
}

# Executes every generator and puts results into an array
sub gen_and(@gens) {
    return sub() {
        return [map { $_->() } @gens];
    }
}
```