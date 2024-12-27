#!perl
use 5.036;
use Sq;
use Sq::Parser qw(p_run);
use Sq::Evaluator;
use Sq::Sig;
use Sq::Test;

# LISP list
my $list;
$list = Sq::Evaluator::parser
    [many => [map =>
        sub(@xs) { sq [@xs] },
        [match => qr/\s* \( \s*/x ], # (
        [or =>
            [many => [or =>
                [match => qr/\s* ([^()\s]++) \s*/x  ], # not () and not white-space
                [delay => sub{ $list }            ]]], # another list
            [match => qr/\s*/]],
        [match => qr/\s* \) \s*/x ]  # )
    ]];

# Tests
is(p_run($list, '()'), Some([[]]), 'list 1');

is(
    p_run($list, '(if (eq 1 1) 1 0)'),
    Some([ ['if', ['eq', 1, 1], 1, 0] ]),
    'list 2');

is(
    p_run($list, '(list 1 2 3 4 5)'),
    Some([ ['list', 1, 2, 3, 4, 5] ]),
    'list 3');

is(
    p_run($list, '
        (define (sum xs)
          (cond
            (empty? xs 0)
            (else (+ (car xs) (sum (cdr xs))))))
    '),
    Some([
        ["define", ["sum", "xs"],
            ["cond",
                ["empty?", "xs", 0],
                ["else", ["+", ["car", "xs"], ["sum", ["cdr", "xs"]]]]]]
    ]),
    'list 4');

is(
    p_run($list, '(display "foo") (display "bar")'),
    Some([ ['display','"foo"'], ['display', '"bar"'] ]),
    'list 5');

done_testing;
