package Sq::Fmt;
use 5.036;
use Sq;
use Sq::Exporter;
our $SIGNATURE = 'Sq/Sig/Fmt.pm';
our @EXPORT    = ();

# This will be a module that help in formating/printing things.
# For example pass it an array of array and it prints a table.

# TODO: Add something to type-check that allows optional field in a hash
#       When a field is defined it must type-check. Otherwise when not provided
#       the type-check is just skipped.
static 'table', sub($href) {
    my $header = $href->{header} // 0;
    my $border = $href->{border} // 0;
    my $aoa    = $href->{data};

    # Calling functions in function-style has the benefit that they always
    # work. You don't need to add a blessing to be sure. This can potential
    # increase performance. But the impact isn't that big.
    #
    # Instead of `sq` you also can use Array->bless, Hash->bless to just bless
    # the first level, sometimes that can also be enough, as every function
    # always returns blessed data. But why bless and then call a method when
    # you just can directly call the function?
    #
    # The intersting part. When everything is called in functional-style
    # no blessing wouldn't be needed anymore. This would interestingly
    # increase performance of the whole system, also makes code easier.
    #
    # The bad part. Exhaustive Lisp nesting is very annoying when you have
    # to put additional "," between every damn element.
    my $maxY = @$aoa;
    return if $maxY == 0;
    my $maxX = Array::map($aoa, call 'length')->max(0);
    return if $maxX == 0;

    # just turn AoA into string lengths and transpose
    my $cols = assign {
        my $sizes = $header ? [$header, @$aoa] : $aoa;
        Array::transpose_map($sizes, sub ($str,$,$) { length $str })
             ->map(call 'max', 0);
    };

    # local $Sq::Dump::INLINE = 0;
    # dump($cols);

    # First all strings in data AoA are expanded to its full column size
    $aoa = Array::map2d($aoa, sub($str,$x,$y) {
        my $length = $cols->[$x];
        sprintf "%-${length}s", $str;
    });
    # Same for header when it is defined
    if ( $header ) {
        $header = Array::mapi($header, sub($str,$x) {
            my $length = $cols->[$x];
            sprintf "%-${length}s", $str;
        });
    }

    # print header
    if ( $header ) {
        if ( $border ) { printf "| %s |\n", $header->join(' | ') }
        else           { print $header->join(" "), "\n"          }
    }
    # print data
    for my $inner ( @$aoa ) {
        if ( $border ) { printf "| %s |\n", $inner->join(' | ') }
        else           { print $inner->join(" "), "\n"          }
    }

    return;
};

# TODO: Restrictions for key?
my sub attr($attr) {
    state $escape = Str->escape_html;
    my (@pairs, $value);
    for my $key ( sort { $a cmp $b } keys %$attr ) {
        $value = $attr->{$key};
        push @pairs, sprintf("%s=\"%s\"", $key, $escape->($value));
    }
    return join(" ", @pairs);
}

# HTML tags that are "void". Means, they have no children and because of
# that they don't need a closing tag. Like: <br>
my $void = type [enum => qw/area base br col embed hr img input link meta source track wbr/];
# Usually i would suggest to use `with_dispatch` as it can handle multiple
# function arguments. But here all cases of `html` are written to only expect
# a single input argument. Either a string, or an array. When your function
# only has a single argument you also can use `type_cond`.
static html => type_cond(
    # [HTML => "string"] -> stays without any change
    type [tuple => [eq => 'HTML'], ['str']] => sub($t) {
        return $t;
    },
    # TODO: script tag has no quoting at all?
    type [tuple => [eq => 'script'], ['str']] => sub($t) {
        return [HTML => sprintf "<script>%s</script>", $t->[1]];
    },
    # when a bare string is passed
    type ['str'] => sub($text) {
        state $escape = Str->escape_html;
        [HTML => $escape->($text)];
    },
    # void tags like br -- i could add type-check that runs into an error
    #                      when void tags are passed with childs
    type [tuple => $void] => sub($t) {
        [HTML => sprintf "<%s>", $t->[0]]
    },
    # void tags with attributes
    type [tuple => $void, ['hash']] => sub($t) {
        [HTML => sprintf "<%s %s>", $t->[0], attr($t->[1])]
    },
    # all other non-void tags, but no attribute or child was passed -- is this illegal?
    type [tuple => ['str']] => sub($t) {
        my ($tag) = @$t;
        [HTML => sprintf "<%s></%s>", $tag, $tag];
    },
    # a tag with attributes and no childs: [a => {href => "url"}]
    type [tuple => ['str'], ['hash']] => sub($t) {
        my ($tag, $attr) = @$t;
        [HTML => sprintf "<%s %s></%s>", $tag, attr($attr), $tag];
    },
    # a tag with attributes and childs: [a => {href => "url"}, [img {src => "url"}]]
    type [tuplev => ['str'], ['hash'], [min => 1]] => sub($args) {
        state $html = html();
        my ($tag, $attr, @tags) = @$args;
        my $inner = join " ", map { $html->($_)->[1] } @tags;
        [HTML => sprintf "<%s %s>%s</%s>", $tag, attr($attr), $inner, $tag];
    },
    # a tag with only childs: [p => [a => {href => "url"}] ]
    type [tuplev => ['str'], ['array']] => sub($args) {
        state $html = html();
        my ($tag, @tags) = @$args;
        my $inner = join " ", map { $html->($_)->[1] } @tags;
        [HTML => sprintf "<%s>%s</%s>", $tag, $inner, $tag];
    },
);

1;