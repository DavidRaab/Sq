package Sq::Sig;
use 5.036;
use Sq;
use Sq::Sig::Option;
use Sq::Sig::Result;
use Sq::Sig::Array;
use Sq::Sig::Hash;
use Sq::Sig::Seq;
use Sq::Sig::Queue;
use Sq::Sig::Heap;
use Sq::Sig::Io;
use Sq::Sig::Fs;
use Sq::Sig::Math;

1;

=pod

=head1 Sq::Sig

This module loads all Signature files for every file that is also
automatically loaded by C<Sq>. By loading C<Sq::Sig> it will now automatically
load.

=over 4

=item * Sq::Sig::Option

=item * Sq::Sig::Result

=item * Sq::Sig::Seq

=item * Sq::Sig::Array

=item * Sq::Sig::Hash

=item * Sq::Sig::Queue

=item * Sq::Sig::Heap

=item * Sq::Sig::Io

=item * Sq::Sig::Fs

=item * Sq::Sig::Fmt

=item * Sq::Sig::Math

=back

=head1 Optional Loadable

=over 4

=item * Sq::Sig::Parser

=back
