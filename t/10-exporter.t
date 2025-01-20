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

package Test2;
use Sq;
use Sq::Exporter;
our @EXPORT    = qw(foo bar);
our $SIGNATURE = 'Sq::Sig::Array';

sub foo() { ... }
sub bar() { ... }

package main;

# Manual import of function
# I do a mnual import, because when importing of Sq::Reflection fails
# because i maybe changed som something in the Exporter than the test still
# runs as far as possible to identify the cause of the problem.
fn has_func => \&Sq::Reflection::has_func;

like(
    dies { Test->import() },
    qr/\Afunction 'test' does not exists/,
    'error on test');

nok(has_func('Test', 'foo'),   'has_func 1');
 ok(has_func('Test', 'hello'), 'has_func 2');
nok(has_func('main', 'hello'), 'has_func 3');

# manual call to import()
Test->import('hello', -sig => 1);

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

# check if foo() and bar() is imported
nok(has_func('main', 'foo'), 'foo not yet imported');
nok(has_func('main', 'bar'), 'bar not yet imported');

Test2->import(-sig => 1, 'foo');

 ok(has_func('main', 'foo'), 'foo is imported');
nok(has_func('main', 'bar'), 'bar not yet imported');

Test2->import(-sig => 1, 'bar');

ok(has_func('main', 'foo'), 'foo is imported');
ok(has_func('main', 'bar'), 'bar not yet imported');

# TODO: tests that really checks if signature was loaded???

done_testing;
