#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Parser -sig => 1;
use Sq::Test;
use Sq::Sig;

# Manual import/alias of a static
*html = Sq->fmt->html;


is(html("click me!"), [HTML => "click me!"], 'text');
is(
    html(['a', {name => "whatever"}]),
    [HTML => '<a name="whatever"></a>'],
    'a');
is(
    html(['body']),
    [HTML => "<body></body>"],
    'body');

    is(html([body =>
        [a => {href => "www.heise.de"}, "Click Me!"],
        [a => {href => "www.cool.de"},  "No Me!"],
    ]),
    [HTML => '<body><a href="www.heise.de">Click Me!</a> <a href="www.cool.de">No Me!</a></body>'],
    'body with multiple a');
one_of(
    html([img => {src=>'url', width=>500}]),
    [
        [HTML => q{<img width="500" src="url">}],
        [HTML => q{<img src="url" width="500">}],
    ],
    'img');
is(
    html([p => "Here is some more text", [a => {href => "url"}], ['br'], "more text"]),
    [HTML => q{<p>Here is some more text <a href="url"></a> <br> more text</p>}],
    'p');

sub ul(@elements) {
    return html([ul => map { html([li => $_]) } @elements]);
}

is(
    ul(qw/one two three/),
    [HTML => '<ul><li>one</li> <li>two</li> <li>three</li></ul>'],
    'ul func');

done_testing;
