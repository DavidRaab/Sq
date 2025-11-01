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
several gigabytes big. And would immediately only read 3 lines one after another,
computes the length of each lines and just saves three integers into one
single array. Then it closes the file. The code that resembles the above would
be similar to.

```perl
my $lengths;
my $fh = open '<', 'whatever.txt' or die "Blub";
while ( my $line = <$fh> ) {
    chomp $line;
    push @$lengths, length($line);
}
close $fh;
```

This piece of code is not possible to represent at all with builtin `map`, `grep`
, `List::Util` or `List::MoreUtils` because all of them only operates on arrays
that fully exists or are loaded into memory.

This lacking feature was also the initial start why I started `Sq`. At the begining
i just implemented `Seq` but because of several reasons it turned out into a
far more complex/complete system.

## Queue

A Queue is not a data-structure to represent data, more a way that pushes
task or things needed todo onto a queue that are then processed in Order
the are pushed (FIFO).

I tried several implemetations, but it came out that a plain Perl Array was
the fastest way and also works fine with push/unshift without growing. So
i am using an Array. But technically the implementation could still change.

I think it is better to use a `Queue` instead of directly an `Array` when that
is what you need. It makes the code more readable as it has some intention
in it. Because a `Queue` is not there for representing data, there is also not
an equality defined for it.

## List

An immutable List implementation. At the current moment use is discouraged because
i focus everything on making `Array` and `Seq` feature complete and making them
as compatible as possible. Doing this for three modules is time consuming.

Technically using `Array` is fine, because all function in `Array` always return
new arrays. So even they are mutable, they are used like immutable values anyway.

Using `List` technically is not more immutable then an `Array`, it only takes
up more memory and is slower compared to the `Array` implementation.

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
takes **O(N)** time instead of **O(Log N)**.

But still in this example, when just adding whole values to an array and just
getting all values at once, then just use `sort`!

Using a Heap is a good option when you for example add multiple elements. Just
get the minimum value, do some processing on it. And during processing multiple
new elements could be added. Then the next smallest element must be used out of
all of them.

Consider that *smallest* is half wrong. When you change the compare function,
you also can traverse something from maximum to minimum. It all depends
on your compare function passed to `new()` or what *smallest* mean to you.
