# Seq::Design::Wrap

Currently Seq->wrap stops at the first `undef`.

```perl
my $list = Seq->wrap(1,2,3,undef,4,5,6)
```

This input will only contain the elements `1,2,3` in a sequence.
Everything after `undef` is discarded.

Another approach would be to skip `undef` so the sequence could
contain `1,2,3,4,5,6` instead.

I don't know if this is a good decision. It would be easier for some
other functions that return such garbage to work with. But is this
really a good idea?

Maybe `undef` is used for a purpose to return between those values.
Yeah , whoever design something like this has no clue about good design.

Skipping `undef` seems like a good idea, but then it messes with such bad
design choices like described.

In this case I think it is better to only pick everything up
to the first `undef`. A user probably will notice this faster and
can evaluate this behaviour.

Maybe `undef` can be skipped. Then some glue code must be written
to handle this case. If `undef` cannot be skipped. Then again, some glue
code must be written to support this strange behaviour.

Aborting on the first `undef` is probably the best we can do to ensure
erroneous behaviour is catched as soon as possible.
