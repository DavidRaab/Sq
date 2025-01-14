package Sq::Fmt;
use 5.036;
use Sq;

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

1;