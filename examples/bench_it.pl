#!/usr/bin/env perl
use v5.36;
use Sq;
use Sq::Sig;

Sq->bench->it(sub { say for 1 .. 1_000 });

