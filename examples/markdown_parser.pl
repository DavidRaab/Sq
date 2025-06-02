#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Parser qw(parser p_run);

# Data-Structure for parsed markdown
my $markdown;
$markdown = union(
    Text       => ['str'],
    H1         => ['str'],
    H2         => ['str'],
    H3         => ['str'],
    H4         => ['str'],
    H5         => ['str'],
    H6         => ['str'],
    Code       => ['str'],
    CodeBlock  => [tuple => ['str'], ['str']], # language text
    Bold       => ['str'],
    Italic     => ['str'],
    Block      => [array => [of => [runion => sub { $markdown }]]],
    Markdown   => [array => [of => [runion => sub { $markdown }]]],
);
$markdown->install;

# Parser itself
sub parse_markdown($str) {
    state $parser = assign {
        my $special = "*`";

        parser [many => [or =>
            # header
            [matchf => qr/^ (\#{1,6}) \s+ (.*) \s*/xms, sub($depth, $title) {
                $depth = length $depth;
                return
                    $depth == 1 ? H1($title) :
                    $depth == 2 ? H2($title) :
                    $depth == 3 ? H3($title) :
                    $depth == 4 ? H4($title) :
                    $depth == 5 ? H5($title) :
                                  H6($title) ;
            }],
            # em
            [matchf => qr/\* ([^\*]+) \*/x,  sub($str) {
                Italic($str)
            }],
            # code block
            [matchf => qr/```(\w+)? \N* \n (.*) ```$/xms, sub($lang, $str) {
                return Str->is_empty($str) ? Code($str) : CodeBlock([$lang, $str]);
            }],
            # code
            [matchf => qr/` ([^`]+) `/x, sub($str) {
                Code($str)
            }],
            # anything else
            [matchf => qr/([^$special]+)/, sub($str) {
                Text($str)
            }],
        ]];
    };

    # first we break the whole string into blocks.
    my $blocks =
        Str->split(qr/\n{2,}/, $str)->map(sub($block){
            p_run($parser, $block)->map(sub($parsed) {
                Block($parsed);
            });
        });
    # dump($blocks);

    # We return a Markdown document
    $blocks->all_some->match(
        Some => sub($blocks) { Markdown($blocks) },
        None => sub { die "Markdown could not be parsed" },
    );
}

# generate HTML from Markdown data-structure
sub markdown2html($md) {
    $md->match(
        Text       => sub($str)   { [HTML   => Str->escape_html($str)] },
        H1         => sub($str)   { [h1     => $str]       },
        H2         => sub($str)   { [h2     => $str]       },
        H3         => sub($str)   { [h3     => $str]       },
        H4         => sub($str)   { [h4     => $str]       },
        H5         => sub($str)   { [h5     => $str]       },
        H6         => sub($str)   { [h6     => $str]       },
        Code       => sub($code)  { [code   => $code]      },
        CodeBlock  => sub($args)  { [code   => $args->[1]] }, # TODO
        Bold       => sub($str)   { [strong => $str]       },
        Italic     => sub($str)   { [em     => $str]       },
        Block      => sub($array) { [p => Array::map($array, \&markdown2html)->expand] },
        Markdown   => sub($array) { [p => Array::map($array, \&markdown2html)->expand] },
    )
}

### Main Program

# read test file
my $content = Sq->fs->read_text('markdown.md')->join("\n");
# parse as data-structure
my $md      = parse_markdown($content);
# dump($md);
# transform data-structure to HTML
my $body    = Sq->fmt->html(markdown2html($md));
# print HTML
say $body->[1];
