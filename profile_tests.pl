#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Path::Tiny;

# my $files = assign {
#     my @files;

#     path('t')->visit(sub{
#         my ( $path, $state ) = @_;
#         push @files, $path if $path->is_file && $path =~ m/\.t\z/;
#     }, { recurse => 1 });

#     sq \@files;
# };

my $files =
    Sq->io->recurse('t')
    ->filter(call 'is_file')
    ->filter(sub($p) { $p =~ m/\.t\z/ });

$ENV{NYTPROF} = "addpid=1";
$files->iter(sub($file) {
    system('perl', '-Ilib', '-d:NYTProf', $file);
});

system('nytprofmerge', glob('nytprof.out.*'), '-o', 'nytprof.out');
system('nytprofhtml', '-f', 'nytprof.out', '--open');
unlink glob('nytprof.out.*');
