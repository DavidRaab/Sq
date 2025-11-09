# What Sq Loads

This is a short overview of everything `Sq` loads by default. The following
packages are available after loading `Sq`. That doesn't mean for every package
there exists one file. A lot of modules are put together into `Sq::Core`.
Loading a single big file instead of hundreds small files is faster on
every Operating-System even on the fastest NVME disk. So this is done
for a performance reason.

* Carp
* Scalar::Util (also loads List::Util)
* Sq::Reflection;
* Sq::Equality
* Sq::Copy
* Sq::Lazy
* Option
* Result
* Sq::Core::DU;    # Discriminated Unions
* Sq::Dump;        # dump(), dumps()
* Sq::Type;        # Type System
* Sq::Array;       # Array
* Sq::Hash;        # Hash
* Sq::Seq;         # Seq
* Sq::Queue;       # Queue
* Sq::List;        # List
* Sq::Heap;        # Heap

because those modules are used nearly everywhere throughout the source-code
in Sq, it loads everything by default. Also all the functionality are somewhat
depended on each other. Array for example has functions that return Option.
Array has some functions that uses equal() and so on. `Sq` is a whole system
just like a programing language with it's basic core data-structures.

# Carp & Scalar::Util

Those modules should be well known among Perl users. When you don't
know them then read its documentation on CPAN. I myself primarily only
use `Carp::croak` and `Scalar::Util::looks_like_number`.

# Default Imports/Exports

When you don't need any default imported function you can write.

```perl
Sq ();
```

and import of any function can be avoided. Also you can choose to only load
certain functions. But this is rarely useful. `Sq` is written
like a programing language. So those functions are like keywords and default
behaviour. Not loading them makes less sense and `Sq` less useful.

Compare it to `Moose`. Loading `Moose` also for example loads functions like
`has`, `extends`, `after`, ...

Not loading those functions only make sense in certain behaviour where you
want to ensure `Sq` itself is loaded. But don't really need any imported
function at all.

Otherwise a lot of functions are imported. See [Sq::API](../../API.pod) for
a full API overview. But here are some of the most useful default imported
functions you might wanna use.

## equal

Sq ships a default equal() implementation that makes a full recursive
data-structure check if two data-structures are the same. In my opinion this
should be the default for most programing language. Working with `Sq` means
you seperate Data and behaviour, and data can be compared by default. No reason
to always reimplement equality again and again for every object.

```perl
if ( equal([1,[2],3], [1,[2],3]) ) {
    print "Is Equal\n";
}
```

The above will print `Is Equal`.

## sq

**Sq** itself ships with an `Array` and `Hash` implementation. Or not. They
are just Pure Perl Array and Hashes. But they are blessed.

```perl
my $array = bless([], 'Array');
my $hash  = bless({}, 'Hash');
```

This is only done for one reason. So you don't must write any function in a
procedrual style. The procedural style is.

```perl
my $sum = Array::sum([1,2,3,4]);
```

But with a blessed Array you also can write

```perl
$array->sum();
```

There are multiple ways on how to create blessed Arrays/Hashes. Writing `sq` in
front of any data-structure goes recursively through a data-structure and adds
`Array` and `Hash` blessing to any non-blessed reference.

For example you can do.

```perl
my $album = sq {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => [
        {title => "Wanna Be Startin’ Somethin", duration => 363},
        {title => "Baby Be Mine",               duration => 260},
        {title => "The Girl Is Mine",           duration => 242},
        {title => "Thriller",                   duration => 357},
        {title => "Beat It",                    duration => 258},
        {title => "Billie Jean",                duration => 294},
        {title => "Human Nature",               duration => 246},
        {title => "P.Y.T.",                     duration => 239},
        {title => "The Lady in My Life",        duration => 300},
    ],
};

# this sums the duration of the tracks array together
my $runtime = $album->{tracks}->sum_by(key 'duration');
```

Here you can see that you just can work with `$album` as any Hash you are used
in Perl. This is an explicit feature. `Sq` adds a blessing `Hash` to the Hash,
but otherwise nothing is added. No hidden or internal key. No Tie or any
other kind of magic is done. It's just to allow calling functions as
methods and allow a method chaining syntax.

Here the Array `$album->{tracks}` got the `Array` blessing added, so you can
call `Array::sum_by` by on it.

Also consider that every *method* is still callable as a procedural function
and an unblessed reference.

```perl
my $runtime = Array::sum_by(
    [
        {title => "Wanna Be Startin’ Somethin", duration => 363},
        {title => "Baby Be Mine",               duration => 260},
        {title => "The Girl Is Mine",           duration => 242},
        {title => "Thriller",                   duration => 357},
        {title => "Beat It",                    duration => 258},
        {title => "Billie Jean",                duration => 294},
        {title => "Human Nature",               duration => 246},
        {title => "P.Y.T.",                     duration => 239},
        {title => "The Lady in My Life",        duration => 300},
    ],
    key 'duration'
);
```

will also work. Even the Array/Hashes are all unblessed. This is a feature.
Also `equal()` correctly works and don't care about the blessings. A blessed
`Array` and a non-blessed `ARRAY` are considered the same.

All functions in `Array` or `Hash` always return blessed Arrays/Hashes. So sometimes
instead of adding a blessing, you also just can use the procedural-style to
start and then after this use the method chaining syntax.

## array(), hash()

Those are short ways to create blessed arrays or hashes. Different to `sq` is
that it doesn't recurse into the data-structure. This sometimes can be easier/faster
to read/write. You also can pass those function as a reference `\&array` that
is sometimes useful. If in doubt, just use `sq`.

```perl
my $array = array(1,2,3,4,5);
my $hash  = hash(
    1 => "Foo",
    2 => "Bar",
);
```

## key(), idx()

When working with **Sq** you pass/create a lot of lambdas. In Some functions
the only thing you do is to create a function to access a hash-field or a
specific index of an array. This is what `key` and `idx` is about.

```perl
$array->sort_by(by_num, sub($hash) { $hash->{id} });
$array->sort_by(by_num, key 'id');

$array->sort_by(by_num, sub($array) { $array->[0] });
$array->sort_by(by_num, idx 0);
```

## by_num(), by_str(), by_stri()

Those are default comparison function for comparing things by string, numbers
or string ignore case.

```perl
$array->sort_by(
    sub($x,$y) { $x <=> $y   },
    sub($hash) { $hash->{id} });

# Much better to read/write
$array->sort_by(by_num, key 'id');
```

## assign {}

Assign let's you create a new scope. The last value is returned.

```perl
my $whatever = assign {
    my $x = ....;
    my $y = ....;
    # a lot of other code
    return $foo;
};
```

This allows you to assign a value to a variable and write code to compute the
value. In this example `$x` and `$y` are scoped and are not accessible outside
the `assign {}`. This is much comparable to a `let`-expression you see in ML
languages.

This is also very helpful with `state` variables that are only initialized a
single time. This allows you to write any complex code that is only executed
a single time.

```perl
sub whatever() {
    state $x = assign {
        # some code to generate $x;
    };
    # other code
}
```

## dump(), dumps()

I cannot live without dumping. In years of development i learned that dumping
just data is the best and fastest way to develope. All kind of debugging is just
crap. Seriously.

Just dump() your whole damn data-structure and you immeditely see what is going
on. No reason on why you should add breakpoints and add variables to a viewer
and so on. This is just hellish slow.

Also in a programing model where you seperate data and code you just can dump
your data and create a test out of it. Consider you have a chain of functions
to somehow mutate or create a new data-structure. Just dump() it. Check
if the data is correct. Then make a test out of it!

```perl
is(
    $hwatever,
    {
        # whatever dump() created
    },
    'is $whatever correct');
```

There is a single rule. When you can dump() data, you also can test it!
Because dump() is so useful it also exists as a method on the
data-structures.

```perl
my $data =
    Array->init(100, sub($idx) { $idx+1 })
    ->dump
    ->map(sub($x) { $x * 2 })
    ->dump;
```

This will not only generate `$data` but gives you two data-structures
dumps of two arrays that was created on STDERR. On the console it will show

```perl
[1,2,3,4,5,  ...]
[2,4,6,8,10, ...]
```

Data-Dumps are made compact and human readable as good it is possible. They
provide some coloring by default. `dumps()` returns the string instead of
auto dumping to STDERR.

## copy()

You ever wanted to create a full deep-recursive copy of a data-structure?
That is what copy() is about.

```perl
my $album1 = {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => [
        {title => "Wanna Be Startin’ Somethin", duration => 363},
        {title => "Baby Be Mine",               duration => 260},
        {title => "The Girl Is Mine",           duration => 242},
        {title => "Thriller",                   duration => 357},
        {title => "Beat It",                    duration => 258},
        {title => "Billie Jean",                duration => 294},
        {title => "Human Nature",               duration => 246},
        {title => "P.Y.T.",                     duration => 239},
        {title => "The Lady in My Life",        duration => 300},
    ],
}
my $album2 = copy($album1);
```

Here `$album2` is not only a full copy of the data-structure, also *Array* and
*Hash* blessings are added to the copy. The original `$album1` stays unaffected.

## Some(), None()

This is an *Option* implemtation. This is another way of saying that something
is either a value, or it is no value. This is an alternative for using `undef`.

The difference is that both are blessed objects and still provide calling methods
on it. This allows writing code where you don't need to check after every operation
if you encountered an `undef` or not.

In OO languages like `C#` for example they added operators like `?.` so you
don't get insane. This is actually a bad implementation because the language
must be added for a single feature. `Option` is the functional way to solve
that problem through a data-type.

Maybe at the beginning when you never worked with it, it is somewhat harder to
understand the benefits. So here is a small example. Consider you want the
Minimum value of an Array. So there is `Array::min` you can call.

But what should it return when the `Array` is empty? Two solutions can be made.

The first one is throwing an exception. This is bad, because an empty array
is not really exceptional code. It just let's your program crash. Maybe in
development you don't encounter the crash because you only test arrays that
has data in it and completely forget about the empty array case. Throwing
an exception means you maybe just forget it, you end up with a bug, and you
later need to fix it. How do you fix it? By writing code that checks the
Array length and then do a branching on it. This is horrible and ugly code.

Another solution is by returning `undef`. Here you end up with the same problem.
Maybe you expect it to return an object, call a method on it. And your
program crashes again. Maybe you just use it as a string or number. Then at
least in Perl you don't get crashes but a lot of warnings about undef values
will appear.

`Option` is the alternative. By default `Array::min` returns
an Option. So to work with the value, you must write explicit code for both
cases. Or just the case when a value is available.

```perl
my $min = $array->min->or(0);  # min value or 0
my $min = $array->min(0)       # provide a default value to min()
my $min = $array->min->match(  # doubles the min value or 0
    Some => sub($x) { $x * 2 },
    None => sub     { 0      },
);

# doubles the min value, if there is one, otherwise does nothing, it still
# will be an Option where you can call ->map() again. or call ->or()
# or other methods.
my $min = $array->min->map(sub($x) { $x * 2 });
```

When you work with `Option` then doing the wrong thing will lead you
immediately into an error.

## Ok(), Err()

This is a `Result` type that is somewhat like an `Option`. But an `Option` is just
there to say. Here is a value, or we have Nothing at all. The Nothing State doesn't
provide any additional value with it.

A `Result` type on the other hand carries the idea that something was `Ok` or is
an `Err` along having some data. For example those both are not the same.

```perl
my $result = Ok(0);
my $result = Err(0);
```

Both are Results. But an `Ok(0)` contains the information about being correct
and the result is `0`. It could for example be the Sum of sum data that turns
out to be `0`.

While `Err(0)` means we have an Error, and the error code is `0`. Could for example
mean that a database operation that wanted to compute the sum had an error.
And `Err(0)` means "Lost Connection" or whatever.

Data can be of any type.

```perl
my $err = Err("Database connection failed");
my $err = Err({ op => 'connect', reason => 'wrong password'});
```

# Some more functions

There are some more functions, but the above are probably the most important
ones you will use most of the time.

# Short Explanation of extra modules

`Sq::Array` and `Sq::Hash` contains all the functions that operate on a
Perl Array or Perl Hash. See the manpages or the API Overview for all the
functions that are provided. Otherwise there are just normal Perl
Arrays and Hashes as explained so far.

## Discrimnated Unions

TODO: Explain Discriminated Unions

## Sq::Reflection

**Sq** itself implements exporting itself. It also has a **static** system
and also does some symbol-table manipulation. Mostly it is also used to
add type-checking for already existing function. The basics symbol-table
manipulations that are needed by **Sq** itself are put into `Sq::Reflection`.

`Sq::Reflection` is not about providing a full Meta-Object-System like
Moose does. It is not needed. This is a procedural/functional module
that keeps functionality simple.

## Seq

`Seq` is a lazy data-structure. It's like an *immutable iterator*. It's like a
C# Linq, Java Streams or F# `Seq` implementation. As the name says, the API is
based on `F# Seq`.

What does *immutable iterator* mean? A typical iterator usage often looks
like.

```perl
my $it = Iterator->new(...);

while ( $it->not_exhausted ) {
    my $value = $it->get_value();

    # Do something with $value

    $it->next;
}
```

A very low-level representation of an iterator. It also only allows iterating
through your iterator a single time. `Seq` on the other hand is an *iterator generator*.

```perl
my $ten = Seq->range(1,10);
```

`$ten` now represents the values `1-10`. But it *always* represents them. You
are usually never ever iterating the iterator yourself. You usually use
one of the many `Seq` functions. Even when you just want to iterator through them
you should use `->iter()` todo so.

```perl
my $sum = 0;
$ten->iter(sub($x) {
    $sum += $x;
});
```

but better is just:

```perl
my $sum1 = $ten->sum;
my $sum2 = $ten->fold(0, sub($x,$acc) { $acc + $x });
```

All three generates the sum. On some other iterator implementation maybe
`$sum2` could be `0` because the iterator was already exhausted. This is not
the case for `Seq`. That is the reason what makes it *immutable*. It's
definition always stays the same.

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

The above shows a difference when this matters. Here `$bigA` creates an Array
with 100 Mio Numbers. It takes time to compute and generate the array and consumes
a lot of memory.

`$bigS` on the other hand represents the same value, without that anything needs to
be computed or a full array of 100 Mio elements needs to be stored.

Doing a `my $sum = $bigS->sum()` for example calculates the sum of it, but
still it doesn't need to store 100 Mio elements in memory. In this case only
two values are needed. The final computed `$sum` and one element. Using a
sequence is like writing.

```perl
my $sum = 0;
for my $x ( 1 .. 100_000_000 ) {
    $sum += $x;
}
```

but you get an API that has all the functionality of `map`, `grep`, `List::Util`
, `List::MoreUtils` and maybe some more. But you get API compatible functions
that work the same for an `Array` or a `Seq`. That's the big difference and
advantage of `Sq`.

## Why not use map, grep, List::Util, List::MoreUtils?

You still can if you prefer. Like i said. `Array` is just a plain perl Array.
You could do.

```perl
my $array = Array->init(100, sub($idx) { Sq->rand->str(1,$idx)->first("") });
my @new   = map { length $_ } @$array;
```

But this has two different syntaxes. You also can use all the List::Util and so
on. Most functionality are available on `Array`, but are slightly different. They
expect functions as arguments and pass values to the function instead of
relying on using the gloabl `$_` variable. And because all of them return
blessed Array/Hashes you can chain functions.

```perl
my $array =
    Array->init(100, sub($idx) { Sq->rand->str(1,$idx)->first("") })
         ->map(sub($x) { length($x) });
```

The advantage of this style is, that `Seq` and `Array` are mostly API compatible
where it is possible. When you have a lazy sequence of strings. Then it looks
the same. For example `Sq->fs->open_text($file)` returns a sequence of
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
open my $fh, '<', 'whatever.txt' or die "Blub";
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
open my $fh, '<', 'whatever.txt' or die "Blub";
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

And when we are at `File::Slurp`. A simple

```perl
my $content = Sq->io->open_text($file)->to_array;
my $content = Sq->io->open_text($file)->cache;
```

can be the same. Special notice is considered to `->cache`. While `to_array`
reads the whole file into memory at once, this is different to `->cache`.
`cache` internally creates an array cache for the iterator. So the iterator
is only every runed once. But again, it only caches so far as it is needed
and is still lazy. You only read 100 lines from that file? Only 100 lines
are ever read and cached into memory. You think this is awesome? I think too!

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

This module implements the `equal()` function.

Numbers and Strings are differentiated by `equal()` so a `equal("0", "0.000")`
will return true! When both strings are considered a number in Perl, they are
also compared by number by `equal`. Otherwise they are string compared
when they are not a reference.

Otherwise when they are a reference, they are compared deeply. `equal()` considers
a Pure Perl Array and `Array` the same!

```perl
if ( equal(Array->init(3, \&id), [0,1,2]) ) {
    # this will be true
}
```

This is a feature ecspecially used in Testing! because the whole Test-suite
`Sq::Test` just uses `equal()` to check if data are the same! It's important as i
said in the beginning that `Array` is just a blessing added to allow method chaining
and are not different to a Pure Perl Array.

`equal()` implements a deep-recursive equality! When Arrays are encountered
then first a check is made if both arrays are of the same size. If not they are
considered unequal. When they are of the same size, each element is compared one
after another, as soon elements are found that are not equal(), then it just
aborts. The same thing happens for a `Hash`.

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
inheritance even more evil that should never be used.

You can add direct reference comparison, and objects with the same reference
can be compared, and that's it. Trying to implement a resolver that somehow
knows how two different references can be compared and which functions should be
picked when they are somehow related or not is simply stupid in my opinion.

Consider you have class `A` and then `B` and `C` that both derive from `A`.
When you now try to compare a `B` with a `C` which equal implementation should be
used? `A::equal`, `B::equal` or `C::equal`?

How about a `BC::equal`? And why anyway should `B` and `C` be equal anyway? When
they are the same then either `B` or `C` is not needed. Two objects of different
classes can never truly be the same. That's just how it works!

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

# Sq::Copy

`Sq::Copy` implements the `copy` function to make a deep-datastructure copy.
By default it understands strings and numbers, `Array`, `Hash`, `Seq`, `Option`
and `Result`. Also `Path::Tiny` is supported.

Like in `Sq::Equality` other data-types can be added.

```perl
Sq::Copy::add_copy('Whatever' => sub($obj) {
    return # however a copy of Whatever is made;
});
```

If `copy()` encounters an unknown reference, it will throw an exception! `copy()`
cannot copy things it doesn't know about how they are copied or if they
even can be copied or not.

# Sq::Type

`Sq` ships it's own type-system. There are a lot of Type-System modules out
there, so why another one? Because `Sq::Type` is very leightweighted and is
build to fit the needs of `Sq` itself. It also correctly works with the
distinction of `ARRAY` and the blessed `Array`.

`Sq::Type` is written in a Combinator Style. So it is completely based that a
type is just a function! And you just combine those functions to build more
complex types.

That's anyway what technically you have todo in a dynamic-typed language. Static
typing means the types are tested and validated at compilation-time, but in a
dynamic typed language you only know the types of certain variables when
you check something by running code. So the only way to test if something is
the right type is by just writing code in a subroutine.

Without any kind of type-system you basically end up writing your type-check
with if-statements. Here is the idea how `Sq::Type` was created. First you usually
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
creating, reusable code starts. Put it into a function that can be re-used.
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
just being digits, the other fields must be strings.

`$is_user` is another type that is expected to be a hash with the keys `id`,
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

This Type-System is different to other Type-Systems in the sense that it
does a check against the definition, a structual approach, not a type-system
by name.

As an example. When you define a class `Point` with `X` and `Y` then you define
a type by it's name. If something is a `Point` or not is simply tested by checking
if an object inherits from `Point` that's it. It's basically just a name check.

If the values in the `Point` are correct or not, are not tested at all. In such
a type-system something is assumed to be correct as long as it has the correct
name or is inherited from it.

Reality shows that this is actually not really true at all. State bugs with
invalid data are common, otherwise we would have no bugs in object-oriented code.

That a class itself can handle it's own state and is always valid is just wishful
thinking far beyond reality. `Sq::Type` doesn't know anything about names. It
does a structural apporach. Whenn you define a `Point` like this.

```perl
my $is_point = type [hash =>
    X => ['num'],
    Y => ['num'],
];
```

then any hash that at least contains an `X` and a `Y` and are numbers is considered
a valid Point! Also the type is not *exclusive*. The above doesn't say that a hash
only is allowed to have an `X` and an `Y`. When it has extra fields, it is still
a valid Point, as long `X` and `Y` are numbers!

This is a feature you should think about. The idea is not to create *closed* types
that only allow *X* and *Y*. Such a type-system fits dynamic-typing a lot better.

You can for example write a function, and only expect fields of a hash, that you
really need to access in this function! When a Hash would have extra fields like
`Z`, `Title`, `Health`, `State` and so on, it wouldn't matter at all, as long
this hash would have an `X` and `Y` and is a number it is a `Point`!

Because of it's structural testing, bugs like invalid state actually becomes
a lot harder to miss, or impossible.

Let's say you would have a class instead of functions, and code like this.

```perl
my $p = Point->new(10,10);
$p->whatever();
```

consider now that somehow the call to `->whatever()` somehow changes `X` and `Y`
and make it invalid. For example `X` is overwritten as a number.

When you then would pass `$p` to a function that expects `$is_point` and you
check it with `t_valid`, it would return `false` and abort. The Hash has become
invalid.

Also consider that your checks can have any logic. You also for example can
restrict numbers in a range. Let's assume you have some function that
also works with Points, but every number should be in a range, have a Min/Max
or something like that. Then you can do so.

```perl
my $is_point = type [hash =>
    X => [num => [range => 0, 100]],
    Y => [num => [range => 0, 100]],
];
```

This also checks if the number is between 0 and 100.

Also this way type-checking and setting/creating values are seperated, what can
be very useful. For either creation of data, manipulation or just simply
performance.

For example you could have an Array of Hashes. You go through ever hash and
do some computation on it. Maybe whatever you want to calculate needs mltiple
loops. So you can do. Only after every step is completed, then you can do
a type-check if the data are in a format you needed.

It's not that you must check any intermediate state, or every intermediate
state is checked at all. As an example, consider you build an `Album` to
represent a *Music Album*. You can write a type like

```perl
my $is_album = type [hash =>
    artist => ['str'],
    title  => ['str'],
    tracks => [array => of => [
        [hash => keys => [
            no       => [int => [min => 1]],
            duration => [int => [min => 0]],
            title    => ['str'],
        ]]
    ]],
];
```

but, when your data is created, you just do how you work with a Hash. You still
can do.

```perl
my $album = {};
$album->{artist} = "Whatever";
$album->{title}  = "Foo";
for my $row ( $somehow->read->data->from->database ) {
    push @{ $album->{tracks} }, $row;
}
```

here you can see how `$album` is built step by step. It's fine. It is just a
Hash. Not on every adding/invocation everything is checked. There is no need to.

Just do the check after you completely build everything. In a Class that is
immutable (or not) you usually have to create all kind of default values. Empty
values, or allow `undef`, and handle `undef` where it is allowed. Maybe even other
stuff. That's also the reason why that whole *Class does it's internal valid state stuff*
is also not working in practice!

The differentation between building and checking for a type also allows *corrections*
to be made. Did you ever read data from a database, CSV-File or other kind of stuff,
and maybe a value wasn't as expected?

You have two different date formats? In your programs type, you expect the track
numbers to start with 1, but your data in your database starts with `0`? No Problem
just go to the tracks and add `+1` to every `no` field first!

Just because you expect some data in a certain type/format, doesn't mean the data
are served to you in that format!

You want `DateTime` objects? But you got JSON? Yeah, then you first must convert
your strings to `DateTime` objects, and so on.

You define the `type` you want, but not all intermediate types. You also don't
must build your final type in one big step. A lot of stuff becomes easier this
way.

And actually also more correct, because a data-structure is always fully tested,
it is not assumed that all data must be correct just because it is of a certain
class.

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
our $SIGNATURE = 'Project/Whatever/Sig/Whatever.pm';
our @EXPORT    = (qw/a b c d e f/);
```

this will ensure that when someone writes.

```perl
use Sq -sig => 1;
use Project::Whatever;
```

that also the signature `Project::Whatever::Sig::Whatever` is loaded.