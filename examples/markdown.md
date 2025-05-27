Tony Hoare once said: *I call it my billion-dollar mistake. It was the invention of the null
reference in 1965.* So, why did he added "null" in the first place? Why was it such a big
mistake. And if it is such a big mistake, what are the alternatives?

# The purpose of null

To understand why it was a mistake, let's look why it was even added in the first place. Let's
assume we have a simple function expecting a `PersonId` that returns a `Person` object. We would
have a function with the following function signature.

    PersonId -> Person

Implementing such a function means, we always have to return a `Person`. But what happens if we
are not able to return a `Person`? What should we return instead? And there can be a multitude of
reasons why that could be the case. A database could not contain a `Person` with your provided
`PersonId`. Also an error could have happened while trying to retrieve data. So overall we have
two kinds of problems that could happen.

1. The passed in value was invalid, or in other words, there doesn't exists a `Person` for the provided input
1. Some kind of error happened that prevents us returning a `Person` object.

So how do we solve that problem? Hoare's answer was the invention of the *null-reference*. A
*null-reference* is compatible with any other type. So instead of returning a `Person` we just
could return a `null` instead.

Our client code calling our function just need to check whether it is `null` or not. As easy as
this sound, this easiness is exactly what leads to numerous errors and problems.

As a first note. Some people will probably tell, that for *errors* we should throw an exception
instead. Actually I leave the discussion for *exception* for another blog post. The important thing
is more that you could return a `null` in the error case. Some functions/libraries do that, and
there is no way you can prevent that. You just have to deal with it, whether you like it or not.

# The problems with null

Now that we understand why we have null. Let's create a list of problems that the implementation
of *null* causes.

The first problem is, we cannot see if a function could return `null` or not. We could just
have written code like this (C#)

```csharp
var person = Person.FetchById(10);
Console.WriteLine(string.Format("Name of Person is {0}", person.Name));
```

The problem is that `Person.FetchById()` sometimes returns a *null-reference*. But we could use
it just like a valid `Person`. But using it just like that, means that sometimes our code will throw a
`NullReferenceException`. Because sometimes, we don't have a `Person`.

To be safe, we have to explicitly check if `Person.FetchById()` returns `null` or not. This results in
code like this:

```csharp
var person = Person.FetchById(10);
if ( person == null ) {
    Console.WriteLine("No Person with ID 10");
}
else {
    Console.WriteLine(string.Format("Name of Person is {0}", person.Name));
}
```

The big problem is that we cannot see from a function type signature that it could return `null` or
not. That means, we have to check **every** function call in our system explicitly because it could
potentially return `null`.

This explicit checking of `null` for every function is sure bother some. So what do we do? Sure, we don't
do that checking on every function. We only check those function that we know they could return a `null`.
Or in other words. We probably rely on *documentation*. Because we all know that *documentation* is always
correct, never has mistakes, and everyone who writes documentation always adds the information if
a function call could return `null` or not. And sure, we as programmers always re-check the whole documentation
for every Class, Method or Function once we updated a library to ensure that the behaviour of all functions
still remains the same!

Jokes aside, sure we don't do that. Not doing that doesn't mean we are bad programmers. The problem is
that doing such kind of things is just silly. Instead of us humans, the language/compiler should do
such kinds of checks for us. We cannot solve the problem with *documentation*. The burden of checking
should be leveraged to the language/compiler instead of us humans. Sure we humans are those who have
to program what happens at some places if we have a `null` or not. But our language should notify us
at compile-time where we have forgotten such checks. We only should add those check where it is really
needed, and the language should notify us where we have forgotten them.

But we don't even have covered all problems yet! We also can pass `null` to other functions. We can
do that because `null` is technically just a value. So we also could do stuff like that.

```csharp
var person = Person.FetchById(10);
DoSomethingWithPerson(person);
```

It basically means, we not only have to check `null` from every function that we call. We also have to
add `null` checks to every function we write, because someone could provide us a `null` value even
if we don't want them. Not doing the checking can actually lead to the problem that somewhere
else, probably even in code we don't have written, we get a `NullReferenceException`.

And the last problem is a so called *Happy path-coding*. Usually we mean it negative that someone
just writes code for the *Happy-Path* expecting that everything works correctly. And as soon there
is some problem, our program blows up and crashes. This leads to very buggy programs. So what we
actually really want is sure we want to code like "Happ-Path", we want to cover as much possible
errors as possible. But we don't want to include some kind of checking and validation throughout
our whole code, nearly at every line, after every function call.

Usually what we want is just write code as if there are no errors (Happy-Path). And only at the end of a
chain we want to check if some-kind of error happened, or probably at selected points inside our chain.
So ideally we want that we are forced to check, but only at specific places where we explicitly want it.
But `null` doesn't provide that. We sure can leave the checks, but then our program will be buggy. As a
result we often add so much `null` checks that our language also could have forced us to write them always
and otherwise return a error. It probably seems impossible how we can get both. Forcing us to check
and gain the safeness to not forget it anywhere, but still only doing the checks when we really want it.

So as a summary, we have the following problems with `null`.

1. We cannot see if a function returns `null` or not
1. We are not forced to add `null` checks, this can lead to `NullReferenceException`
1. Because every function could return `null` we also have to check every function
1. We cannot *skip* the checking and do it at some later point
1. We can pass `null` as valid values. And because we are not forced to check for `null`, this
   can throw `NullReferenceException` at some other places.
1. We also have to check every function argument for `null`
1. It destroys *Happy Path-coding*

# Optionals

Actually retro-fixing *null* in a language is nearly impossible. There exists often some kind of *hack-ish*
ways on how to fix it. But it usually feels not natural, or it doesn't fix all problems. So let's look at
F# that does not support `null` *directly*. So how do we write a functions that sometimes can return an
absence of a value?

The answer is, it is not possible. We actually cannot write a function that sometimes returns `Person`
or not. What we really have to do is return another type instead. What we really need to return is an
`Option` instead. An `Option` is just a data-type on its own. But an Option can either be `Some value`
or `None`. You can compare it to a `bool` that is either `true` or `false`. The only difference is that in
the case of `true` or `Some` it can carry an additional value with it. Option is already part of F#
but you could easily define it yourself like this.

```fsharp
type Option<'a> =
    | None
    | Some of 'a
```

Or to say it otherwise. It is just a *generic* type. That either could be `None` or `Some 'a`. With this
kind of idea we now can create types like `Option<int>`, `Option<Person>`, `Option<Foo>`, ... and so on.
There is also an alternative style for writing a generic type `int person`, `Person option`, `Foo option`.
We will use this style, because this is also the style how it is often shown by the IDE (like Visual Studio).
Also note that the `Option` type itself defined in F# uses a small letter `option` instead of `Option`.

So what we really have is not a function `PersonId -> Person` we really have:

    PersonId -> Person option

Or in other words. A function taking a `PersonId` that returns an `option` that either can
contain a `Person` or don't contain anything. The first improvement is now that we can see
clearly which functions can return a value or not. We don't have to rely on documentation
anymore. Code itself is the best documentation at all! So lets assume we want to
print the Name of a person, what do we have to write now?

```fsharp
let person = Person.fetchById 10
match person with
| None        -> printfn "No Person with Id 10"
| Some person -> printfn "Name of Person is %s" person.Name
```

At first, this doesn't look like an improvement over the `if` checking. We still have to check for
either `Some` or `None`. So why is that better?

1. The important point is, not every function returns an `option`. You only have to add this check if
   a function returns an optional.
1. You are *forced* by the language at *compile-time* to add the checks if a function returns an `option`.

You cannot write code like this.

```fsharp
let person = Person.fetchById 10
printfn "Name of person is %s" person.Name
```

This will give you a *compile-time error*. Because `person` is of type `option` and `option` don't
contain a field `Name`. It basically means, you cannot create `NullReferenceException` because you cannot
forget to add the checking. And you only have to really check those functions that could return an option.

Actually that eliminates all problems we have, but let's go over the problems once more to describe
why they are eliminated.

## 1: We can identify functions returning *Nothing*

It is just part of the function signature.

    int -> int option

it can return an `int` or not

    int -> int

This will always return an `int`

## 2: We must check

We cannot access a value directly. `option` is a type on its own. If we want to get the inner value
we have to *Pattern Match* against an optional.

```fsharp
let person = Person.fetchById 10
match person with
| None        -> printfn "No Person with Id 10"
| Some person -> printfn "Name of Person is %s" person.Name
```

Runtime `NullReferenceException` are not possible anymore

## 3: Not every function returns `option`

That means we only need to *Pattern Match* those function that return an `option`. Functions
that don't return `option` also cannot be Pattern Matched! If we would Pattern Match against
a value that is not an `option` we get an error. Once again, everything happens already at
compile-time. That means you can see the error already in your IDE.

## 4: We can skip the checking

`option` is just a type like any other. That means you can return an option from your function.
But you also can pass `option` as a value around. The important thing is, you only need to do
the checking once you also need the value inside of the `option`. But note that you cannot pass
a `int option` to a function expecting a `int`. Both are different types. If a function expects
`int` you must unwrap the value inside the `option`. Well that isn't quite correct, because
you can automate this process, but we will look later at this in more detail.

## 5 and 6: Passing `option`

We can pass `option` as a valid value. But only to those function that expects a `option`. We
cannot implicitly pass it. And a function expecting an `option` as a value also must *Pattern Match*
the argument.

So it cannot happen that values sometimes are `option` or not. Either they are, and we must check. Or
we don't have to check at all.

# Happy Path-Coding

Happy Path-Coding needs some further explanations. Previously i said that F# don't support `null`
but this isn't quite right. F# runs on the .NET platform, and the runtime supports the concept
of `null`. From F# we can call any code that was written for example in C#. So we have to add
`null` checks for data-types, functions and so on that where not directly written in F#.

To deal with functions that returns `null` we often write wrappers and turn the result into an `option`.
For example the `Int32.TryParse` function is a good candidate to show the idea.

```fsharp
let tryParse (str:string) =
    match Int32.TryParse str with
    | false,_ -> None
    | true,x  -> Some x
```

We now created a `tryParse` function. When we look at the signature we see `string -> int option`. Or
in other words. A function that can return an `int` or not. Let's assume we now parse three strings.

```fsharp
let x = tryParse "10"
let y = tryParse "20"
let z = tryParse "30"
```

and now we want to add them together. Ideally in a *Happy-Path* coding we could directly write.

```fsharp
let result = x + y + z
```

But the problem is that `x`, `y` and `z` are `int optional`. So we cannot add `optional` values.
We first have to unwrap them. And it makes sense that we cannot do it. What for example should the
the result be if some of the parsing failed? Should it just add those that where valid? Should
the whole *computation* be aborted as soon one was invalid? Let's stick for the last one. As soon
one is invalid, the whole computation should be invalid. Or in our case now. We now have to *Pattern
Match* every variable, check if it is `Some value`. If true, we check the next variable, if `None`
the whole computations returns `None`.

```fsharp
let result =
    match x with
    | None -> None
    | Some extractedX ->
        match y with
        | None -> None
        | Some extractedY ->
            match z with
            | None -> None
            | Some extractedZ -> Some (extractedX + extractedY + extractedZ)
```

Man, that is some ugly code! We have the benefit that we are forced to check, we cannot have
`NullReferenceException` and all of the other benefits. Also `result` is now an `int option`. And
it makes sense. As soon one of `x`, `y` or `z` was not a valid `int`, also `return` would be `None`.
But it seems we have lost any kind of our *Happy-Path* coding. Because now we have to check every value
directly. Isn't there some way to be as close to `let result = x + y + z`, so if every value was `Some`
it does it calculation, and otherwise it just returns `None`? So instead of checking every value directly
we just want to work with the values as they would be normal non-optional values? But as soon one value
is `None` just everything is `None`? The answer is. Yes, there is a way to achieve that!

But at this point i will not show how to build the solution for yourself. And actually there even exists
two solutions to solve it. Either way through a so called *Applicative Functor* or the *Maybe Monad*.
So let's look how both solution would look like.

## Applicative Functor

The approach with an *applicative functor* works that we can *upgrade* any kind of functions. Let's
first create a function that added our three variables together.

```fsharp
let addThree a b c = a + b + c
```

Now we have a function with the function signature

    int -> int -> int -> int

Or in other words, a function taking three `int` as an argument, and returning an `int`. But as learned
so far we could not just call.

```fsharp
let result = addThree x y z
```

Because or `x`, `y` and `z` are `int optional`. So with an *Applicative Functor* we could *upgrade* our
*addThree* function. So we could do something like this.

```fsharp
let addThreeOptionals = Option.lift3 addThree
```

So we have a function `Option.lift3`. We can pass any three argument function to it and what we get
back is a new three argument function that now could be `optional`. When we expect the signature
of our `addThreeOptionals` function (You can hover over `addThreeOptionals` if you don't know yet)
we now see `addThreeOptionals` has the following signature.

    int optional -> int optional -> int optional -> int optional

Or in other words. We now have a function taking three arguments, sum then only when all of them
are `Some`, and returning another `int optional` as a result. What we now can do is just write.

```fsharp
let resultWithA = addThreeOptionals x y z // Some 60
```

But as soon as we have an optional in it, we just get a `None` overall back.

```fsharp
let w = tryParse "hallo"
let ax = addThreeOptionals x y w // None
```

But we are not forced to create an intermediate function like `addThreeOptionals`. We also could
have written.

```fsharp
let bx = Option.lift3 addThree x y z
```

It just means, you can just write any kind of function, and you never have to care if they are `option`
or not. You always can assume that you have a valid value. If your function should also be able to work
with `optional`, you just pass your function to `Option.lift1`, `Option.lift2`, `Option.lift3` and so
on to *upgrade* your function. So you just can stay on the Happy-Path as long as you wish!

But all of your functions will return `option` now. So at some point in your application you have
to check whether your computation was successful or not. But it is up to you where you do it or
where it makes sense to check it. So instead of checking `x`, `y` and `z` directly, you just can work
with the values, directly add them but if you want to print the result of your `addThreeOptionals`
function. You have to Pattern Match.

## Maybe Monad

Another solution is the so called *Maybe Monad*. F# supports a feature named *Computation Expression*
that are syntactic sugar for this kind of computations. Let's just look how our code could look like
with a *Maybe Monad*.

```fsharp
let resultWithMaybeA = maybe {
    let! x = tryParse "10"
    let! y = tryParse "20"
    let! z = tryParse "30"
    return x + y + z
}
```
As you see, we just can wrap our code inside a `maybe { ... }`. What you now see is a special
syntax only available in a *Computation Expression*. You can write `let!` instead of just `let`.
A `let!` basically does the *unwrapping* of a value for you.

Remember that `tryParse` actually returned an `int option`. But if you hover over `x` it is
just an `int`. `let!` basically can turn a `int option` to an ordinary `int` for you. So you
can work with the result of `tryParse` just as if it is a normal value. But
overall `resultWithMaybeA` is still an `int optional`. In those case it will be `Some 60`.

If you would have written.

```fsharp
let resultWithMaybeB = maybe {
    let! x = tryParse "10"
    let! y = tryParse "hallo"
    let! z = tryParse "30"
    return x + y + z
}
```

`resultWithMaybeB` would be `None`. This is because `tryParse "hallo"` would result in `None`. And this
will abort the `maybe` construct at this point, and it would overall just return `None`.

# Summary

`null` is evil, because you have to add a lot of checking to get it right, a language like C# don't
support you in trying to find all places where you forgot or have to add checking to get a correct
program.

Optionals solve the problem as you already get forced to check for `None` at compile-time. And
you only need to do it at places where an Optional could be returned. With the idea of
an *Applicative Functor* or the *Maybe Monad* you can still write code at places where you don't
want to add explicit checking, without losing the benefits of optionals.

In some future blogs I will show you in more detail how *Applicative Functors* and the *Maybe Monad*
works. So you can build your own constructs !

# Further Reading

 * [Null has no type, but Maybe has](http://blog.ploeh.dk/2015/11/13/null-has-no-type-but-maybe-has/)
 * [The Option Type](http://fsharpforfunandprofit.com/posts/the-option-type/)
 * [Wikibook - Option Type](https://en.wikibooks.org/wiki/F_Sharp_Programming/Option_Types)

