#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

package Test;
use Sq;
use Sq::Exporter;
our @EXPORT = qw(test hello world);

sub hello() {
    return 'Hello';
}

sub world() {
    return 'World';
}

package main;

# Manual import of function
*has_func = \&Sq::Reflection::has_func;

like(
    dies { Test->import() },
    qr/\Afunction 'test' does not exists/,
    'error on test');

nok(has_func('Test', 'foo'),   'has_func 1');
 ok(has_func('Test', 'hello'), 'has_func 2');
nok(has_func('main', 'hello'), 'has_func 3');

Test->import('hello');
 ok(has_func('main', 'hello'), 'has_func 4');
nok(has_func('main', 'world'), 'has_func 5');

is(hello(), 'Hello', 'hello correct');

like(
    dies { Test->import('whatever') },
    qr/\Afunction 'whatever' is not in \@EXPORT/,
    'import not defined');

like(
    dies { Test->import('test') },
    qr/\Afunction 'test' does not exists/,
    'function not in @EXPORT fails');

done_testing;
