# How Loading Sq works

Loading Sq first loads the module

* Carp
* Scalar::Util

because those modules are used nearly everywhere throughout the source-code
in Sq, it loads it there by default. So you also always can use a full
qualified call to those functions. This is what I do in Sq itself.

When someone else writes code using Sq, he should use/load those modules.
There is no guranty those modules will always be loaded. Even if the
chance that i ever remove those are nearly zero.

When i for a reason choose to not use those modules, i will change Sq at every
place, so nothing is broken.

By default Sq exports a lot of functions by default. This will not be changed.
But by writing.

```perl
Sq ();
```

an export of any function can be avoided. Also you can choose to only load
certain functions. But this is only useful in certain cases. `Sq` is written
like a programing language. So those functions are like keywords and default
behaviour. Not loading them makes less sense and `Sq` less useful.

Compare it to `Moose`. Loading `Moose` also loads for example functions like
`has`, `extends`, `after`, ...

Not loading those functions only make sense in certain behaviour where you
want to ensure `Sq` itself is loaded. But don't really need any imported
function at all.

# Signatures

By writing

```perl
use Sq -sig => 1;
```

Signatures are loaded. Signatures are a feature that adds type-checking to
functions input and output. Activating Signatures adds Signatures to all
modules (so far written) or modules that uses `Sq::Exporter` that have a
Signature defined.

# Sq::Exporter

When signatures was activated a default global variable `Sq::LOAD_SIGNATURES`
is set to `1`. By default it is `0`. When loading any module with `Sq::Exporter`
it checks the Global Variable. When it is `1` it loads the module that is
defined in the global current package variable defined as `SIGNATURE`.

So a typical use of `Sq::Exporter` looks like.

```perl
package Project::Whatever;
use 5.036;
use Sq;
use Sq::Exporter;
our $SIGNATURE = 'Project/Sig/Whatever.pm';
our @EXPORT    = (qw/a b c d e f/);
```

this will ensure that when someone writes.

```perl
use Sq -sig => 1;
use Project::Whatever;
```

that also the signature `Project::Whatever::Sig::Whatever` is loaded.

# Default Loaded Modules / Packages

Loading `Sq` by default always loads the following modules in order.

```perl
# Load Core
use Sq::Reflection;
use Sq::Core;
use Sq::Core::DU;

# Load Collections
use Sq::Collections::Array;
use Sq::Collections::Hash;
use Sq::Collections::Seq;
use Sq::Collections::Queue;
use Sq::Collections::List;
use Sq::Collections::Heap;

# Load other basic functionality
use Sq::Dump;
use Sq::Equality;
use Sq::Copy;

# on ->import() call
require Sq::Type;
```

* `Sq::Reflection` is a small default module that is able to easily install sub-refs
  as named functions into a module. It also provides reading those functions. It
  also keeps track of static defined functions.
* `Sq::Core` contains. `Option`, `Result` and `Sq::Core::Lazy`
* `Sq::Core::DU` contains the implementation of Discriminated Unions.

The collections should be self-explanatory. The build the default data-structures
of `Sq` itself. Consider that `Array` and `Hash` are not a re-impletation of
an Array or Hash. The default Perl ones are used. Those defaults just get a
blessing added so you can call functions not only on a procedural style.

```perl
my $array = Array::windowed(Array->init(100, sub($idx) { $idx + 1 }), 2);
```

you also can write it as a chain.

```perl
my $array =
    Array->init(100, sub($idx) { $idx + 1 })
         ->windowed(2);
```

Only a blessing is added. You always can use any Array or Hash like a normal Perl
Array or Hash. This is completely fine todo.

```perl
my $array =
    Array->init(100, sub($idx) { $idx + 1 })
         ->windowed(2);

for my $x ( @$array ) {
    # do whatever with $x
}
```

No extra information is ever added to those Arrays or Hashes. This is done for
compatibility. Any other Perl Module also should be able to accept those Arrays
or Hashes created by `Sq` as long as it doesn't do any type-checking.

because then it may be break. As then a blessed `Array` is passed instead of
being a unblessed reference of type `ARRAY`.

# Forward / Back-Reference

Sometimes in Array/Hash i use functionality like `equal()`. For example `Array::contains`
can check if any value is sinde an array, and it uses the `equal()` function
that does a *value equal* with a recursive comparision.

But `equal` is just loaded later with `Sq::Equality`. Also you cannot load `Sq`
in `Sq::Array` because `Sq::Array` is loaded by `Sq` by default. This would otherwise
lead to an inifity loop of trying to load modules.

That's the reason why any of those default modules must use a full function call
like `Sq::Equality::equal()` when needed. Because the function lookup of those
function is defered until you first call those functions.

Because `Sq::Equality` is also loaded by default by loading `Sq` this also doesn't
create any problems.

# Short Explanation of those extra modules

## Seq

`Seq` is a lazy data-structure. It's like a *immutable iterator*. It's like a
C# Linq, Java Streams or F# `Seq` implementation. As the name says, the API is
based on `F# Seq`.

What does *immutable iterator* means? A typical iterator usage often looks
like.

```perl
my $it = Iterator->new(...);

while ( $it->not_exhausted ) {
    my $value = $it->get_value();

    # Do something with $value

    $it->next;
}
```

A very low-level representation of an iterator. It also only allows iterating through
your iterator a single time. `Seq` on the other hand is an *iterator generator*.
Writing.

```perl
my $ten = Seq->range(1,10);
```

`$ten` now represents the values `1-10`. But it *always* represents them. You
are usually never ever iterating the iterator yourself. You usually use
one of the many `Seq` functions. Even when you just want to iterator through them
you use `->iter()` todo so.

```perl
my $sum = 0;
$ten->iter(sub($x) {
    $sum += $x;
});
```

but better is just:

```perl
my $sum1 = $ten->sum->or(0);
my $sum2 = $ten->sum(0);
my $sum3 = $ten->fold(0, sub($x,$acc) { $acc + $x });
```

all three generates the sum. `$sum3` is not empty because `$ten` was already
iterated. `$ten` just represents an iterator from 1-10. That's what
is somehow makes it *immutable*. It's definition always stays the same.

The difference between a *typical iterator* is that you can iterate `$ten` as
often as you wish. This way, you also always can use an iterator itself again
and again to build more complex things. For example.

```perl
my $concat = Seq->concat($ten, $ten, $ten, $ten);
```

is completely fine. `$concat` is now another new sequence that contains
the values from 1-10 four times. Or not. Because it is lazy. When you never ask
for values. Absolutely nothing is ever computed.

```perl
my $bigA = Array->range(1,100_000_000);
my $bigS = Seq->range  (1,100_000_000);
```

The above shows a difference where this matters. Here `$bigA` creates an Array
with 100 Mio Numbers. It takes time to compute and generate the array and consumes
some amount of memory.

`$bigS` on the other hand represents the same value, without that anything needs to be
computed or a full array of 100 Mio elements needs to be stored.

Doing a `my $sum = $bigS->sum(0)` for example calculates the sum of it, but
still it doesn't need to store 100 Mio elements in memory. In this case only
two values are needed. The final computed `$sum` and one element. Using
sequence is like writing.

```perl
my $sum = 0;
for my $x ( 1 .. 100_000_000 ) {
    $sum += $x;
}
```

but you get an API that has all the functionality of `map`, `grep`, `List::Util`
, `List::MoreUtils` and maybe some more. But you get those functions for an `Array`
and a lazy sequence.

## Why not use map, grep, List::Util, List::MoreUtils?

You still can if you prefer. Like i said. `Array` is just a plain perl Array.
You could do.

```perl
my $array = Array->init(100, sub($idx) { Sq->rand->str(1,$idx)->first("") });
my @new   = map { length $_ } @$array;
```

But this has two different syntaxes. You also can use all the List::Util and so
on. Most functionality are available on `Array`, but are slightly different. They
expect functions as arguments and pass values to the function. But because of
returning blessed values you can chain them.

```perl
my $array =
    Array->init(100, sub($idx) { Sq->rand->str(1,$idx)->first("") })
         ->map(sub($x) { length($x) });
```

The advantage of this style is, that `Seq` and `Array` are mostly API compatible
where it is possible. When you have a lazy sequence of strings. Then it looks
the same. For example `Sq->fs->open_text($file)` returns you a sequence of
strings. So you can write.

```perl
my $lengths =
    Sq->fs->open_text('whatever.txt')
      ->map(sub($x) { length($x) });
```

and `$lengths` now represents the length of every line in a file. But consider
it is still lazy. Same API, but as long you never ask for any data, the file is
never opened and nothing is computed. When you for example just do.

```perl
my $lengths =
    Sq->fs->open_text('whatever.txt')
      ->map(Str->length)
      ->to_array(3);
```

only then a computation starts. `to_array(3)` forces an eager evaluation as it
wants to turn the sequence into an array with the limitation of only
reading 3 entries from the sequence. But only ever 3 lines from `whatever.txt`
are read into memory. And also not all three lines at once. The file could be
several gigabytes big and would only read 3 lines one after another,
computes the length of each lines and just saves three integers into one
single array. Then it closes the file. The code that resembles the above would
be similar to.

```perl
my $lengths;
my $lines_read_so_far = 0;
my $fh = open '<', 'whatever.txt' or die "Blub";
while ( my $line = <$fh> ) {
    chomp $line;
    push @$lengths, length($line);
    last if ++$lines_read_so_far >= 3;
}
close $fh;
```

consider you want only certain lines that match a specifix regex. And then just
the first 3 of it, and then the length from it. This is easy and understandable in `Sq`.

```perl
my $lengths =
    Sq->fs->open_text('whatever.txt')
      ->rx(qr/\AFOO:/)    # everything that matches the regex
      ->map(Str->length)
      ->to_array(3);
```

This is the same as the following code.

```perl
my $lengths;
my $lines_read_so_far = 0;
my $fh = open '<', 'whatever.txt' or die "Blub";
while ( my $line = <$fh> ) {
    chomp $line;
    if ( $line =~ m/\AFOO:/ ) {
        push @$lengths, length($line);
        last if ++$lines_read_so_far >= 3;
    }
}
close $fh;
```

This pieces of code are not possible to represent at all with builtin `map`, `grep`
, `List::Util` or `List::MoreUtils` because all of them only operates on arrays
that fully exists or are loaded into memory. It is sometimes okay todo that, but
when not, it is annoying to write low-level code like above. With `Sq` you just can
switch between `Array` and `Seq` and have the same API.

It is very easy to write your own `Seq` or something that generates a `Seq`.
For example even network sockets. Reading from a CSV file (Sq->io->csv_read)
just return `Seq`. You can easily combine multiple sequences and have a lot of
operations on it that can be hard to write yourself.

Also you can compare sequences with `equal()` by default. For example comparing
if two text-files are the same is just a.

```perl
my $file1 = Sq->io->open_text($file1);
my $file2 = Sq->io->open_text($file2);
if ( equal($file1, $file2) ) {
    # When files are equal
}
```

This is basically how `Sq->fs->compare_text($file1, $file2)` is implemented itself!
And it all works in a lazy meaner! That means the comparison ends as soon something
is not equal. The first line don't match? Then just a single line from each file
was ever read into memory. You compare two files of 5 GiB in size? No problem,
both files need to be read completely when they are identical. But never more
than one line of each file is read into memory.

It will take some time until this complets on big files, but your program will run
and will work. Compare this as if you would try to use `File::Slurp` on such big files
and work with other modules that operate on whole Arrays. Sure you can write
the low-level code again! No Problem, i can write everything i have written in
`Sq` myself, as otherwise i would not be able to write `Sq`. But writing such
code is usually more code, buggy and you repeat youself like a thousand times.
And i have gotten sick of it.

This lacking feature of a `Seq` was also the initial start why I started `Sq`.
At the begining i just implemented `Seq` but because of several reasons it turned
out into a far more complex/complete system.

## Queue

A Queue is not a data-structure to represent data, more a way that pushes
tasks or things needed todo onto a queue that are then processed in Order
the are pushed (FIFO).

I tried several implemetations, but it came out that a plain Perl Array was
the fastest way and also works fine with push/unshift without growing. So
i am using an Array. But technically the implementation could still change.

I think it is better to use a `Queue` instead of directly an `Array` when that
is what you need. It makes the code more readable as it has some intention
in it. Because a `Queue` is not there for representing data, there is also not
an equality defined for it. This is actually a feature.

When you try to compare a `Queue` something is probably wrong!

## List

An immutable List implementation. At the current moment it's use is discouraged
because I focus on making `Array` and `Seq` feature complete and making them
as compatible as possible. Doing this for three modules at the same time is time
consuming.

Technically using `Array` is fine, because all function in `Array` always return
new arrays. So even they are mutable, they are used like immutable values anyway.

Using `List` technically is not more immutable then an `Array`, it only takes
up more memory and is slower compared to the `Array` implementation.

Maybe I also decide to drop the `List`. At the moment it stays here, maybe
some people find it helpful to digest the source-code and how it works.

## Heap

A Heap is a special data-structure that allows **O(Log N)** insertion and
**O(Log N)** removal of the smallest element. This is for example used
in Dijkstra Algorithm. Also you can implement a heap-Sort with it, and technically
is one of the fastest algorithm compared to *QuickSort* or *MergeSort*.

```perl
# new() expects a compare function
my $heap = Heap->new(sub($x,$y) { $x <=> $y });

# you also can use add() with multiple args
for my $x ( 1,3,10,2,100,5,9 ) {
    $heap->add($x);
}

# add two additional elements.
$heap->add(0,50);

is(
    $heap->remove(),
    0,
    'remove smallest element');

# here also remove_all() could be used
my @sorted;
while ( defined(my $x = $heap->remove) ) {
    push @sorted, $x;
}

is(\@sorted, [1,2,3,5,9,10,50,100], 'manual heap removal');
```

Using a Heap is faster than using *Insertion Sort*, because adding a new element
takes **O(Log N)** time instead of **O(N)**.

But still in this example, when just adding whole values to an array and just
getting all values at once, then just use `sort`!

Using a Heap is a good option when you for example add multiple elements. Just
get the minimum value, do some processing on it. And during processing multiple
new elements could be added. Then the next smallest element must be used out of
all of them.

Consider that *smallest* is half wrong. When you change the compare function,
you also can traverse something from maximum to minimum. It all depends
on your compare function passed to `new()` or what *smallest* mean to you.

**Not yet complete**

# Sq::Dump

This module implements the `dump()` and `dumps()` function that are imported by
default in `Sq`. You just can write.

```perl
dump($any);
```

and by default it creates a data-structure dump of whatever you have. It correctly
also dumps a `Seq`, `Option` or `Result`. It also (tries) to dump all data
as how you would create them. For example when you write.

```perl
dump(Some(1));
```

then you get

```perl
Some(1)
```

as a data-dump. You don't get it's internal representation of it, like for
example `Data::Dumper` would do.

```perl
my $VAR1 = bless([1], 'Option');
```

it also recurses into `Option`, `Result` or `Seq` values. For example dumping
a `Seq` with any other Dumping module, would be completely useless, as it is
a lazy sequence.

In `Sq` by default it tries to just dump the first `100` values of it. This
is configurable by `Sq::Dump::SEQ_AMOUNT`. It's data-dumping is meant to be
readable by human. So it is very compact. Usually in 99% of cases you just can
Copy & Paste a dump, and put it into a test!

By default it jumps with Colors on, as it assumed to be used on the console.

`my $str = dumps()` returns a string, that can be used when you don't want
to print it to STDERR by default. Could also be you want to log them into a
file?

By default `dump()` understands `Seq`, `Array`, `Hash`, `Queue`, `Option`,
`Result`, `DateTime`, Discriminated Unions (another feature of Sq), picks
other colors for Numbers and Strings. `Benchmark`, `Path::Tiny` and sub-refs.

When Hashes are dumped, they keys are always sorted before dumping. This makes
comparing two Hashes in a dump easily compareable by a Human.

Other Perl-Modules/Objects can be easily added to dumping.

```perl
Sq::Dump::add_dump($ref, sub($x) {
    # return a string that represents $x
});
```

In the future a lot more Objects and commonly used Modules will be added, so
it understand them out of the box. `DateTime` for example is such an object.

```perl
dump(DateTime->new({year => 2025, month => 1, day => 1}))'
# prints: DateTime("2025-01-01T00:00:00")
```

Here it shows the 99% of being capable of just Copy & Paste. Because with
`DateTime("2025-01-01T00:00:00")` you cannot create an object. But it is
very human readable and easy to read/understand in a Data Dump.

This will be improved in the future. Maybe a `DateTime()` function will be
imported by default in `Sq`. But i also picked this style, because potentially
this Data-Dumps can also be read from other languages this way.

# Sq::Equality

This module implements the `equal()` function that is imported by `Sq` by default.

Numbers and Strings are differentiated by `equal()` so a `equal("0", "0.000")`
will return true! When both strings are considered a number in Perl, they are
also compared by number by `equal`. Otherwise they are string compared
when they are not a reference.

Otherwise when they are a reference, they are compared deeply. `equal()` considers
a Pure Perl Array and `Array` the same! That means a blessed Array created from
`Sq` can be directly compared with an unblessed reference.

```perl
if ( equal(Array->init(3, \&id), [0,1,2]) ) {
    # this will be true
}
```

This is a feature ecspecially used in Testing! because the whole Test-suite `Sq::Test`
just uses `equal()` to check if data are the same! It's important as i said in
the beginning that `Array` is just a blessing added to allow method chaining
and are no difference of a Pure Perl Array.

`equal()` implements a deep-recursive equality! When Arrays are encountered
then first a check is made if both arrays are of the same size. If not they are considered
unequal. When they are of the same size, each element is compared one after another,
as soon elements are found that are not equal(), then it just aborts. The same
thing happens for a `Hash`.

`equal()` is fast when data are not equal, as it can abort very fast. Otherwise
when equal, everything must be compared in depth.

Does that sound inefficent? Consider that before I used my own Test-Suite
with `Sq::Test` i used `Test2` and that one was around 2-3 times slower!

Like in `Sq::Dump` you can add other objects for comparison.

```perl
Sq::Equality::add_equality($ref, sub($x,$y) {
    # return 0 or 1 if $x or $y are the same
});
```

Consider that no sub-classing/inheritance works or is implemented. And will never
be. I consider object-orientation in generall flawed in many many ways, and `Sq`
doesn't try to be an object-oriented module. Even when OO is used, then i consider
inheritance even more evil, that should never be used.

You can add direct reference comparison, and objects with the same reference
can be compared, and that's it. Trying to implement a resolver that somehow
nows how two different references can be compared and which functions should be
picked when they are somehow related or not is simply stupid in my opinion.

Even when two objects share a common class, they cannot be the same! That's
just how it works.

In the future, again, some common objects will probably be added, but don't
consider much. When working with `Sq` the idea is to differentiate between
data and code.

You should build your data with just `Array`, `Hash`, `Option`, `Result` and
maybe `Seq`. And that's it. It's fine to add equality for objects that
are meant to represent data and are probably immutable. For example `Path::Tiny`
is already supported, as it just represents a Path-String.

Also things like Date, Time values and so on can be added. But adding high-complex
mutable state object crap is just completely out of the scope what should be
compareable.

If there is no direct way of dumping and no direct way of directly creating
an object in it's final state (not through a bunch of method calls) then
adding it for Equality or Dumping is maybe wrong!

# Sq::Type

`Sq` ships it's own type-system. There are a lot of Type-System modules out
there. `Moose` implemented some types based on classes. You got `Type::Tiny`
that extended on this. Even if i don't know what is *Tiny* on `Type::Tiny`.

By default it ships over 40+ Perl packages/classes with the typical overhead
that object-orientation offers. `Sq::Type` is a single file with around 700 lines
of code.

`Sq::Type` is written in a Combinator Style. So it is completely based that a
type is just a function! And you just combine those functions to build more
complex types.

That's anyway what technically you have todo in a dynamic-typed language. Static
typing means the types are tested and validated at compilation-time, but in a
dynamic typed language you only know the types of certain variables when the
code is executed. So the only way to test if something is the right type is
by just writing code in a subroutine.

Without any kind of type-system you basically end up writing your type-check
with if statements. Here is the idea how `Sq::Type` was created. First you usually
start with simple if-statements.

```perl
sub whatever($int) {
    Carp::croak "Not an integer!\n" if not $int =~ m/\A\d+\z/;
}
```

but. Why not create reusable pieces of functions instead? Maybe you put the above
test just into a function.

```perl
sub t_int($any) {
    Carp::croak "Not an integer!\n" if not $int =~ m/\A\d+\z/;
}

sub whatever($int) {
    t_int($int);
}
```

This isn't exactly how `Sq::Type` works. But this is the first idea how
creating, reusable code starts. Put it just into a function, that can be re-used.
Now just checking for int values has become far more easier!

But again. `Sq::Type` are Combinators. For example, you can write this.

```perl
use Sq;
use Sq::Type;

my $is_address = t_hash(t_keys(
    street => t_str,
    city   => t_str,
    state  => t_str,
    zip    => t_match(qr/\A\d+\z/),
));

my $is_user  = t_hash(t_keys(
    id      => t_str,
    first   => t_str,
    last    => t_str,
    address => $is_address,
));
```

Loading `Sq::Type` loads a lot of `t_` functions into the namespace. The above first
defined an `$is_address` variable that says that `address` must be a hash with
the keys `street`, `city`, `state` and `zip`. `zip` must match the regex of
just being digits.

`$is_user` is another type that is expects again a hash with the keys `id`,
`first`, `last` and `address` being of type `$is_address`. Those types
can be runed with `t_run`, `t_valid` or `t_assert`.

```perl
my $ok   = t_run  ($is_user, {}); # Err("some error message")
my $bool = t_valid($is_user, {}); # 0
t_assert($is_user, {});           # Throws Exception
```

by default `Sq` imports a function named `type` that allows you to define
a type by a data-structure. Here is how it works. By default a function call
looks like this.

```perl
function($arg1, $arg2, $arg3);
```

in general you can convert any function call by converting it into a data-structure.
In a dynmic-typed language you just put it into an array.

```perl
['function', $arg1, $arg2, $arg3];
[function => $arg1, $arg2, $arg3]; # consider how => is used here
```

now this is not a function call. Nothing is ever executed. But it still completely
represent of what should be called! This is an important idea from Lisp, as any List
or data in LISP is actually just code! You can go through a data-structure and
then based on a name/string/atom you can pick a function that should be executed
in that place. This step is also named *Evaluation* and where *eval* has it's
name.

An implementation that get's any kind of data-structure, and you give it a
dispatch-table with the name to function mapping is found in `Sq::Evaluator`.
So here is what you also can write.

```perl
use Sq;

my $is_address = type [hash => [keys =>
    street => ['str'],
    city   => ['str'],
    state  => ['str'],
    zip    => [match => qr/\A\d+\z/],
]];

my $is_user  = type [hash => [keys =>
    id      => ['str'],
    first   => ['str'],
    last    => ['str'],
    address => $is_address,
]];
```

so every function call just turns into an array where the first argument
is just a string of the `t_` function that should be called. Because it is
just a data-structure and `type` knows it is about types, the leading `t_` don't
have to be written anymore.

Because `type()` is also a function imported by default by `Sq`, you can always
write types in such a style without directly importing `Sq::Type` and any
other additional function. The result of the `type()` functions are executable
with `t_run`, `t_valid` or `t_assert`.

By default a `is_type` function is imported by default by `Sq` that just maps to
`Sq::Type::t_valid`.

But rarely you must do this. With `Sq::Signature` a system is provided that allows
you to add type-checking to any function that already is defined. It does the
adding and swapping of functions for you and uses the types generated by `Sq::Type`.

Also additional functions are available in `Sq` that directly expects a Type and
does the execution for you!

For example you can write

```perl
my $only_users = $array->keep_types($is_user);
```

and it will only filter/keep those values that match your user definition!

## Types are Open

Different to maybe some other type-systems a type is matched when all of the
definitions are correct. When a data-type contains more data than the check,
it will still be valid! For example you can define a point

```perl
my $is_point = type [hash =>
    X => ['num'],
    Y => ['num'],
];
```

then any hash that at least contains an `X` and a `Y` and are numbers is considered
a valid Point! This is a big feature that you should think about!

A hash that has extra keys with `Z`, `Title`, `Health`, `State` and so on is
also a Valid Point when it contains an `X` and `Y` that is a number!
