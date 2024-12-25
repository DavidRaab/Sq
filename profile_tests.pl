#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Path::Tiny;

my $files = assign {
    my @files;

    path('t')->visit(sub{
        my ( $path, $state ) = @_;
        push @files, $path if $path->is_file && $path =~ m/\.t\z/;
    }, { recurse => 1 });

    sq \@files;
};

$ENV{NYTPROF} = "addpid=1";
$files->iter(sub($file) {
    system('perl', '-Ilib', '-d:NYTProf', $file);
});

my @profiles = glob("*.out.*");
system('nytprofmerge', @profiles, '-o', 'merge.out');
unlink @profiles;
system('nytprofhtml', '-f', 'nytprof.out', '--open');
unlink 'nytprof.out';
