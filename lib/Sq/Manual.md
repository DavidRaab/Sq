# Sq::Manual

This is an overview of already written documentation.

## Sequence or Array

In [Sequence or Array](lib/Sq/Manual/SeqOrArray.pod) I compare `Array`
and `Seq` and describe it's advantages and when you should use `Seq`.

## API Documentation

## Other

### L<Sq::Manual::FromSub>

An in-depth tutorial on how to use Seq->fromSub to create your own
constructor functions and make other Perl Code / Modules work with
Seq.

## DESIGN

#### L<Sq::Manual::Design::Wrap>

Describes why certain operations like C<< Seq->wrap >> stops at C<undef>

#### L<Sq::Manual::Design::MinMax>

Describes why functions like C<Sq::max> uses a mandatory C<$default> argument.
