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


is(html("click me!"), "click me!", 'text');
is(
    html(['a', {name => "whatever"}]),
    '<a name="whatever"></a>',
    'a');
is(
    html(['body']),
    "<body></body>",
    'body');

    is(html([body =>
        [a => {href => "www.heise.de"}, "Click Me!"],
        [a => {href => "www.cool.de"},  "No Me!"],
    ]),
    '<body><a href="www.heise.de">Click Me!</a> <a href="www.cool.de">No Me!</a></body>',
    'body with a');
# is(
#     html([img => {src => 'url', alt => "Description", width=>500, height=>600}]),
#     '<body><a href="www.heise.de">Click Me!</a> <a href="www.cool.de">No Me!</a></body>',
#     'img');
is(
    html([p => "Here is some more text", [a => {href => "url"}], ['br'], "more text"]),
    '<p>Here is some more text <a href="url"></a> <br></br> more text</p>',
    'p');

sub ul(@elements) {
    return html([ul => map { html([li => $_]) } @elements]);
}

is(
    ul(qw/one two three/),
    '<ul><li>one</li> <li>two</li> <li>three</li></ul>',
    'ul func');

done_testing;
