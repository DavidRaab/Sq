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
    InlineCode => ['str'],
    Code       => ['str', 'str'], # language text
    Bold       => ['str'],
    Italic     => ['str'],
    # TODO: Array of Markdown
    Block      => ['str'],
    Markdown   => [array => [of => [runion => sub { $markdown }]]]
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
                ["h".$depth, $title];
            }],
            # em
            [matchf => qr/\* ([^\*]+) \*/x,  sub($str) {
                [em => $str]
            }],
            # code block
            [matchf => qr/```(\w+)? \N* \n (.*) ```$/xms, sub($lang, $str) {
                [code => $str]
            }],
            # code
            [matchf => qr/` ([^`]+) `/x, sub($str) {
                [code => $str]
            }],
            # anything else
            [matchf => qr/([^$special]+)/, sub($str) { $str }],
        ]];
    };

    # first we break the whole string into blocks.
    my $blocks =
        Str->split(qr/\n{2,}/, $str)->map(sub($block){
            p_run($parser, $block)->map(sub($parsed) {
                # TODO: Block can contain multiple markdown elements not just string
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
        Text       => \&id,
        H1         => \&id,
        H2         => \&id,
        H3         => \&id,
        H4         => \&id,
        H5         => \&id,
        H6         => \&id,
        InlineCode => \&id,
        Code       => \&id,
        Bold       => \&id,
        Italic     => \&id,
        Block      => sub($str) { [p => $str] },
        Markdown   => sub($array) {
            return $array->map(sub($md) { markdown2html($md) })
        }
    )
}

# read test file
my $content = Sq->fs->read_text('markdown.md')->join("\n");
# parse as data-structure
my $md      = parse_markdown($content);
# dump($md);
# generate html from it

my $body = assign {
    my $aoh = markdown2html($md)->map(Sq->fmt->html);
    unshift @$aoh, "body";
    return Sq->fmt->html($aoh)->[1];
};

# dump($body);
say $body;