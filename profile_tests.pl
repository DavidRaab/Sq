#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;

my $files =
    Sq->fs->recurse('t')
    ->filter(call 'is_file')
    ->filter(sub($p) { $p =~ m/\.t\z/ });

$ENV{NYTPROF} = "addpid=1";
$files->iter(sub($file) {
    system('perl', '-Ilib', '-d:NYTProf', $file);
});

system('nytprofmerge', glob('nytprof.out.*'), '-o', 'nytprof.out');
system('nytprofhtml', '-f', 'nytprof.out', '--open');
unlink 'nytprof.out', glob('nytprof.out.*');
