#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

my $files =
    Sq->fs->recurse('t')
    ->keep(call 'is_file')
    ->keep(sub($p) { $p =~ m/\.t\z/ });

$ENV{NYTPROF} = "addpid=1";
$files->iter(sub($file) {
    system('perl', '-Ilib', '-d:NYTProf', $file);
});

system('nytprofmerge', glob('nytprof.out.*'), '-o', 'nytprof.out');
system('nytprofhtml', '-f', 'nytprof.out', '--open');
unlink 'nytprof.out', glob('nytprof.out.*');
