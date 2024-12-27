#!perl
use 5.036;
use Sq;
use Sq::Parser qw(p_run);
use Sq::Evaluator;
use Sq::Sig;
use Sq::Test;

sub parser($array) {
    return Sq::Evaluator::parser($array);
}

# LISP list
my $list;
my $value =
    parser [or =>
        [match => qr/\s* \b(\d++)\b           /x ], # int
        [match => qr/\s* ([a-zA-Z0-9?+]++) \s* /x ], # name
        [delay => sub{ $list }                  ]]; # another list

$list =
    parser [map =>
        sub(@xs) { sq [@xs] },
        [match => qr/\s* \( \s*/x ], # (
        [or =>
            [many => $value],
            $value,
            [match => qr/\s*/]],
        [match => qr/\s* \) \s*/x ]  # )
    ];

sub run($p,@v) {
    return p_run($p,@v)->map(call 'flatten');
}

is(run($list, '()'), Some([]), 'list 1');
is(
    run($list, '(if (eq 1 1) 1 0)'),
    Some([ 'if', ['eq', 1, 1], 1, 0 ]),
    'list 2');
is(
    run($list, '(list 1 2 3 4 5)'),
    Some(['list', 1, 2, 3, 4, 5]),
    'list 3');
is(
    run($list, '
        (define (sum xs)
          (cond
            (empty? xs null)
            (else (+ (car xs) (sum (cdr xs))))))
    '),
    Some(
        ["define", ["sum", "xs"],
            ["cond",
                ["empty?", "xs", "null"],
                ["else", ["+", ["car", "xs"], ["sum", ["cdr", "xs"]]]]]]
    ),
    'list 4');

done_testing;
