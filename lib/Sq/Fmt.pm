package Sq::Fmt;
use 5.036;
use Sq;
use Sq::Exporter;
our $SIGNATURE = 'Sq/Sig/Fmt.pm';
our @EXPORT    = ();

# This will be a module that help in formating/printing things.
# For example pass it an array of array and it prints a table.

### Types for table().
# when data is array of hash, then header must be specified, border is optional
# but must be bool when specified.
my $table_aoh = [hash =>
    [keys =>
        header => [array => [of => ['str']]],
        data   => [array => [of => ['hash']]],
    ],
    [okeys =>
        border => ['bool'],
    ]
];

# otherwise data must be an AoA containing strings and header/border is optional
my $table_aoa = [hash =>
    [keys =>
        data => [array => [of => [array => [of => ['str']]]]]
    ],
    [okeys =>
        header => [array => [of => ['str']]],
        border => ['bool'],
    ],
];

# TODO: Support Seq as data
static table => with_dispatch(
    type [tuple => $table_aoa] => sub ($args) {
        my $header = $args->{header} // 0;
        my $border = $args->{border} // 0;
        my $aoa    = $args->{data};

        # check that we have at least one entry
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
    },
    type [tuple => $table_aoh] => sub($args) {
        state $table = table();
        # on the data array, call "extract" on every hash to turn it into an array
        # with the defined order in "header". This returns optionals that are then
        # mapped with "or" so non existing keys in the hash turn into empty strings.

        # map every element in data that is an hash
        my $aoa = Array::map($args->{data}, sub($hash) {
            # "extract" creates an array of those keys in the exact order they
            # are specified, but as optionals. We map every element and turn every
            # None value (keys that didn't exists in the hash) into an empty string
            Hash::extract($hash, $args->{header}->@*)->map(call 'or', "");
        });

        # call table again with the AoA
        $table->(Hash::with($args, data => $aoa));

        return;
    },
);

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