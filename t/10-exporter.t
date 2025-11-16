#!perl
use 5.036;
use Sq -sig => 1;
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

sub whatever() {
    return "Whatever";
}

package Test2;
use Sq;
use Sq::Exporter;
our @EXPORT = qw(foo bar);

sub foo() { ... }
sub bar() { ... }

package main;

# Manual import of function
# I do a mnual import, because when importing of Sq::Reflection fails
# because i maybe changed som something in the Exporter than the test still
# runs as far as possible to identify the cause of the problem.
fn has_func => \&Sq::Reflection::has_func;

dies { Test->import() }
qr/\Afunction 'test' does not exists/,
'import() dies when @EXPORT contains a function that does not exists';

nok(has_func('Test', 'foo'),   'has_func 1');
 ok(has_func('Test', 'hello'), 'has_func 2');
nok(has_func('main', 'hello'), 'has_func 3');

# manual call to import(), only import "hello()"
Test->import('hello', -sig => 1);

 ok(has_func('main', 'hello'), 'hello was imported');
nok(has_func('main', 'world'), 'world is not imported');

is(hello(), 'Hello', 'hello correct');

dies { Test->import('whatever') }
qr/\Afunction 'whatever' is not in \@EXPORT/,
'importing an existing function not in @EXPORT fails';

dies { Test->import('test') }
qr/\Afunction 'test' does not exists/,
'function in @EXPORT but does not exists also fails';

# check if foo() and bar() is imported
nok(has_func('main', 'foo'), 'foo not yet imported');
nok(has_func('main', 'bar'), 'bar not yet imported');

Test2->import(-sig => 1, 'foo');

 ok(has_func('main', 'foo'), 'foo is imported');
nok(has_func('main', 'bar'), 'bar not yet imported');

Test2->import(-sig => 1, 'bar');

ok(has_func('main', 'foo'), 'foo is imported');
ok(has_func('main', 'bar'), 'bar not yet imported');

Test2->unimport('bar');

 ok(has_func('main', 'foo'), 'foo is imported');
nok(has_func('main', 'bar'), 'bar not yet imported');

Test2->unimport();

nok(has_func('main', 'foo'), 'foo is imported');
nok(has_func('main', 'bar'), 'bar not yet imported');

# Check if Sq can unimport all it's functions and still work as intended
package Whatever;
use Sq;

# use an imported function
sub check {
    return get_type([]);
}

# unimport functions
no Sq;

package main;

 ok(has_func('Whatever', 'check'),    'has check');
nok(has_func('Whatever', 'get_type'), 'imports should be deleted');
 is(Whatever->check, 'Array',         'call check()');

# TODO: tests that really checks if signature was loaded???

done_testing;
