package Sq::Core::Str;
use 5.036;
use Sq;
use Sq::Exporter;
our $SIGNATURE = 'Sq/Sig/Str.pm';
our @EXPORT    = ();

static length  => sub($str) { length $str      };
static lc      => sub($str) { lc $str          };
static uc      => sub($str) { uc $str          };
static chomp   => sub($str) { chomp $str; $str };
static chop    => sub($str) { chop $str; $str  };
static reverse => sub($str) { reverse $str     };
static ord     => sub($str) { ord $str         };
static chr     => sub($str) { chr $str         };
static hex     => sub($str) { hex $str         };

static trim   => sub($str) {
    $str =~ s/\A\s+//;
    $str =~ s/\s+\z//;
    return $str;
};

static collapse => sub($str) {
    $str =~ s/\A\s+//;
    $str =~ s/\s+\z//;
    $str =~ s/\s+/ /g;
    return $str;
};

static nospace => sub($str) {
    $str =~ s/\s+//g;
    return $str;
};

# TODO: I could detect/load HTML::Escape and when present use that as
#       escape_html(), otherwise the pure perl version is used.
static escape_html => sub($str) {
    state %mapping = (
        '"' => '&quot;',
        '&' => '&amp;',
        "'" => '&#39;',
        '<' => '&lt;',
        '>' => '&gt;',
        '`' => '&#96;',
        '{' => '&#123;',
        '}' => '&#125;',
    );
    return $str =~ s/(["&'<>`{}])/$mapping{$1}/rge;
};

static repeat => sub($str, $count) {
    return $str x $count;
};

static starts_with => sub($str, $start) {
    my $len = length $start;
    return 1 if substr($str, 0, $len) eq $start;
    return 0;
};

static ends_with => sub($str, $end) {
    my $len  = length $end;
    my $size = length $str;
    if ( $len < $size ) {
        my $start = $size - $len;
        return 1 if substr($str, $start, $len) eq $end;
    }
    return 0;
};

static contains => sub($str, $contains) {
    return 1 if index($str, $contains) >= 0;
    return 0;
};

static chunk => sub($str, $size) {
    my @chunks;
    my $max     = length $str;
    my $current = 0;
    while ( $current < $max ) {
        push @chunks, substr($str, $current, $size);
        $current += $size;
    }
    return bless(\@chunks, 'Array');
};

static map => sub($str, $f) {
    return join "", (map { $f->($_) } (split //, $str));
};

static keep => with_dispatch(
    type [tuple => ['str'], ['sub']] => sub($str, $f) {
        return join "", grep { $f->($_) } (split //, $str);
    },
    type [tuple => ['str'], ['regex']] => sub($str, $regex) {
        return join "", grep { $_ =~ $regex } (split //, $str);
    },
);

static remove => sub($str, $f) {
    return join "", grep { $f->($_) == 0 } (split //, $str);
};

static split => sub($regex, $str) {
    return sq [ split $regex, $str ];
};

1;