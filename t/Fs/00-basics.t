#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use Sq::Sig;
use FindBin qw($Dir);
use Path::Tiny;

ok(Sq->fs->compare_text(
    path($Dir, 'data', 'hop-preface.txt'),
    path($Dir, 'data', 'hop-preface.md'),
), 'Higher-Order Perl Preface');

my $file = Sq->fs->read_text(path($Dir, 'data', 'hop-preface.txt'))->cache;

is($file->length, 52, 'file lines');
is($file->rxm(qr/lisp/i)->length, 15, 'lines mentioned lisp');
is(
    $file->rx(qr/lisp/i)->first,
    Some("Around 1993 I started reading books about Lisp, and I discovered something\n"),
    'first line containing lisp');
is(
    $file->rx(qr/lisp/i)->first,
    Some("Around 1993 I started reading books about Lisp, and I discovered something\n"),
    'first line containing lisp');

ok(Sq->fs->recurse($Dir)->length > 3, 'more than 3 files');
ok((Sq->fs->recurse($Dir)->length > Sq->fs->children($Dir)->length),
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

is(
    Sq->fs->sha512($Dir, 'data', 'hop-preface.md'),
    Ok("3518cc17afa576ef870ab0e869eb0ebf49fe137a97c6aec50ba05d72ce89331057403eaffbec8bd7dee38694bef67ebcd70a15ee41ee6e13e74ea731db3633cc"),
    'sha512 1');

nok(Sq->fs->sha512($Dir, 'data', 'NotExisting'), 'sha512 2');

is(
      Sq->fs->read_raw  (100, $Dir, 'data', 'hop-preface.md')->to_array(1),
    [ Sq->fs->read_bytes(100, $Dir, 'data', 'hop-preface.md')->get ],
    'read_bytes');

# write_text(file,string)
{
    my $txt = "hällö\n";
    my $tmp = Path::Tiny->tempfile("SqTestXXXXXXX");
    ok(utf8::is_utf8($txt),            'string is unicode');
    ok(Sq->fs->write_text($tmp, $txt), 'write file');
    ok(utf8::is_utf8($txt),            'string stays unicode');
    is(
        Sq->fs->read_text($tmp),
        seq { "hällö" },         # newlines are auto-removed when reading a file
        'written file same as string');
}

# write_tex(file,aoa)
{
    my $content = [
        "# Hällö",
        "",
        "This is an example for writing multiple lines",
        "stored in an array",
    ];

    my $tmp = Path::Tiny->tempfile("SqTestXXXXXXX");
    ok(utf8::is_utf8($content->[0]),       'string is unicode');
    ok(Sq->fs->write_text($tmp, $content), 'write file');
    ok(utf8::is_utf8($content->[0]),       'string stays unicode');
    is(
        Sq->fs->read_text($tmp)->to_array,
        $content,
        'written file same as string');
}

# write_tex(file,seq)
{
    my $content = Seq->concat(
        seq { "# Hälö" },
        Seq->init(10, sub($idx) { "1" x $idx }),
    );

    my $tmp = Path::Tiny->tempfile("SqTestXXXXXXX");
    ok(Sq->fs->write_text($tmp, $content), 'write file');
    is(
        Sq->fs->read_text($tmp),
        $content,
        'written file same as string');
}

done_testing;
