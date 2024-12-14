package Sq::Core::Measure;
use 5.036;

=head1 Units of Measure

Some implementaion / library to not just have plain int/floats. Instead
have real numbers like meters, kilometers, temperature, size, ...

I mean we always need to work with numbers and a lot of different representaions
of it. We need to convert "1kb", "1 kib" and other stuff. We either get
them through external data, parsing from a string, we need validation and
conversion. And those are always the same.

Why re-implement it every time? It something i hated todo for a very long time.
Web applications need them, command line arguments need them. when you read data
from a database you probably need them. From a Config file and so on ...

Maybe it doesn't need the whole Units of Measure like F# supports it. But
just be able to parse and convert them is already a big relief.

=cut


1;
