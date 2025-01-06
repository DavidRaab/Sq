#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;
use Sq::Test;
use FindBin qw($Dir);
use Path::Tiny;

ok(Sq->fs->compare_text(
    path($Dir, 'data', 'hop-preface.txt'),
    path($Dir, 'data', 'hop-preface.md'),
), 'Higher-Order Perl Preface');

my $file = Sq->fs->read_text(path($Dir, 'data', 'hop-preface.txt'));

is($file->length, 52, 'file lines');
is($file->rxm(qr/lisp/i)->length, 15, 'lines mentioned lisp');
is(
    $file->keep(sub($line) { $line =~ m/lisp/i })->first->or(""),
    "Around 1993 I started reading books about Lisp, and I discovered something\n",
    'first line containing lisp');
is(
    $file->rx(qr/lisp/i)->first->or(""),
    "Around 1993 I started reading books about Lisp, and I discovered something\n",
    'first line containing lisp');

ok(Sq->fs->recurse($Dir)->length > 3, 'more than 3 files');
ok(
    (Sq->fs->recurse($Dir)->length > Sq->fs->children($Dir)->length),
    'recurse must contain more files than children');

is(
    Sq->fs->read_raw(10, $Dir, 'data', 'hop-preface.txt')->take(5),
    seq {
        "# Preface\n",
        "\nA well-kn",
        "own saying",
        " in the pr",
        "ogramming "
    },
    'read_raw');

is(
    Sq->fs->read_text_gz($Dir, 'data', 'hop-preface.md.gz')->take(1),
    seq { "# Preface\n" },
    'read one line from gz');

is(
    Sq->fs->read_text   ($Dir, 'data', 'hop-preface.md'),
    Sq->fs->read_text_gz($Dir, 'data', 'hop-preface.md.gz'),
    'comparing gziped file with plain text');

is(
    Sq->fs->read_text($Dir, 'data', 'utf8.txt'),
    seq {
        "# Höder\n",
        "\n",
        "Töxt with söme höder.\n",
    },
    'read utf8.txt');

is(
    Sq->fs->read_text_gz($Dir, 'data', 'utf8.txt.gz'),
    seq {
        "# Höder\n",
        "\n",
        "Töxt with söme höder.\n",
    },
    'read utf8.txt.gz');

is(
    Sq->fs->read_text($Dir, 'data', 'utf8.txt'),
    seq {
        "# Höder\n",
        "\n",
        "Töxt with söme höder.\n",
    },
    'read utf8.txt');

is(
    Sq->fs->read_text   ($Dir, 'data', 'utf8.txt'),
    Sq->fs->read_text_gz($Dir, 'data', 'utf8.txt.gz'),
    'compare utf8.txt with utf8.txt.gz');

done_testing;
