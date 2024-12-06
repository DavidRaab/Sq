#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Path::Tiny;

my @files; path('t')->visit(sub{
    my ( $path, $state ) = @_;
    push @files, $path if $path->is_file && $path =~ m/\.t\z/;
}, { recurse => 1 });
my $files = sq \@files;

$ENV{NYTPROF} = "addpid=1";
$files->iter(sub($file) {
    system('perl', '-Ilib', '-d:NYTProf', $file);
});

my @profiles = glob("*.out.*");
system('nytprofmerge', @profiles, '-o', 'merge.out');
system('rm', @profiles);
system('nytprofhtml', '-f', 'merge.out', '--open');
