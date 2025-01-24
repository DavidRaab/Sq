#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Parser;
use Sq::Test;

# Manual import/alias of a static
fn html => Sq->fmt->html;

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

is(
    html([img => {src=>'url', width=>500}]),
    [HTML => q{<img src="url" width="500">}],
    'img');

is(
    html([p => "Here is some more text", [a => {href => "url"}], ['br'], "more text"]),
    [HTML => q{<p>Here is some more text <a href="url"></a> <br> more text</p>}],
    'p');

# Just create functions that generate HTML
{
    my sub ul(@elements) {
        return html([ul => map { html([li => $_]) } @elements]);
    }

    is(
        ul(qw/one two three/),
        [HTML => '<ul><li>one</li> <li>two</li> <li>three</li></ul>'],
        'ul func');
}

# complex example i just converted from HTML to data-structure
{
    my $html = html(
        [form => {name=>"pricecalc", onsubmit=>"return false", onchange=>"calculate(this)"},
            [fieldset =>
                [legend => "Work out the price of your car"],
                [p => "Base cost: £52000."],
                [p => "Select additional options:"],
                [ul =>
                    [li => [label => [input => {type=>"checkbox", name=>"brakes"}, "Ceramic brakes (£1000)"  ]]],
                    [li => [label => [input => {type=>"checkbox", name=>"radio"},  "Satellite radio (£2500)" ]]],
                    [li => [label => [input => {type=>"checkbox", name=>"turbo"},  "Turbo charger (£5000)"   ]]],
                    [li => [label => [input => {type=>"checkbox", name=>"sticker"}, q{"XZ" sticker (£250)}   ]]],
                ],
            [p => "Total: £", [output => {name=>"result"}]],
        ],
        [script => "calculate(document.forms.pricecalc);"],
    ]);

    is(
        $html,
        [HTML => "<form name=\"pricecalc\" onchange=\"calculate(this)\" onsubmit=\"return false\"><fieldset><legend>Work out the price of your car</legend> <p>Base cost: £52000.</p> <p>Select additional options:</p> <ul><li><label><input name=\"brakes\" type=\"checkbox\">Ceramic brakes (£1000)</input></label></li> <li><label><input name=\"radio\" type=\"checkbox\">Satellite radio (£2500)</input></label></li> <li><label><input name=\"turbo\" type=\"checkbox\">Turbo charger (£5000)</input></label></li> <li><label><input name=\"sticker\" type=\"checkbox\">&quot;XZ&quot; sticker (£250)</input></label></li></ul> <p>Total: £ <output name=\"result\"></output></p></fieldset> <script>calculate(document.forms.pricecalc);</script></form>"],
        'complex example');
}

# table generation
{
    my sub row(@fields) {
        html([tr => map { html([td => $_]) } @fields]);
    }
    my sub table(@rows) {
        html([table => map { row(@$_) } @rows]);
    }

    is(
        table(
            [qw/1 2 3/],
            ["foo", "bar", "baz"],
        ),
        [ "HTML", "<table><tr><td>1</td> <td>2</td> <td>3</td></tr> <tr><td>foo</td> <td>bar</td> <td>baz</td></tr></table>" ],
        'HTML Table');
}

done_testing;
