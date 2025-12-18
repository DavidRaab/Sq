#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

print "This program just prints every test file and the amount of lines ",
      "in every file.\n";

my $files =
    Sq->fs->recurse('t')->choose(sub($file) {
        if ( -f $file && $file->basename =~ m/\.t$/ ) {
            return Some [
                $file->stringify,

                Sq->fs->read_text($file)
                ->remove(sub($line) { $line =~ m/\A\s*+#/  }) # remove comments
                ->remove(sub($line) { $line =~ m/\A\s*+\z/ }) # remove empty lines
                ->length
            ]
        }
        return None;
    })
    ->sort_by(by_num, idx 1)
    ->rev;

Sq->fmt->table({
    header => [qw/File Lines/],
    data   => $files,
    border => 0,
});

printf "\nTotal Test Lines: %d\n", $files->sum_by(idx 1);
