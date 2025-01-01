#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;
use FindBin qw($Dir);
use Path::Tiny;

ok(Sq->fs->compare_text(
    path($Dir, 'data', 'hop-preface.txt'),
    path($Dir, 'data', 'hop-preface.md')
), 'Higher-Order Perl Preface');

my $file = Sq->fs->read_text(path($Dir, 'data', 'hop-preface.txt'));

is($file->length, 52, 'file lines');
is($file->regex_match(qr/lisp/i)->length, 15, 'lines mentioned lisp');
is(
    $file->keep(sub($line) { $line =~ m/lisp/i })->first->or(""),
    "Around 1993 I started reading books about Lisp, and I discovered something\n",
    'first line containing lisp');

ok(Sq->fs->recurse($Dir)->length > 3, 'more than 3 files');
ok(
    (Sq->fs->recurse($Dir)->length > Sq->fs->children($Dir)->length),
    'recurse must contain more files than children');

done_testing;
