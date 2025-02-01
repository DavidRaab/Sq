#!/usr/bin/env perl
use 5.036;
# use utf8;
# use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

# I have this script in one of my folders. It usually contains 'mp4' files
# captured from my smartphone. But those video files from the smartphone
# do not have the best compression. I reencode the files and save the new
# reencoded file under the same name just with another file-ending.

# This script helps me quickly to identify which 'mp4' file is maybe already
# reencoded to a m4v file. Then i delete that file.

my $files =
    Sq->fs
    ->children('.')
    ->keep(call 'is_file')
    ->map (call 'stringify')
    ->group_by(sub($file) { $file =~ s/\. .*\z//rx })
    ->remove(  sub($k,$v) { $k eq ""               })
    ->keep(    sub($k,$v) { $v->length > 1         });

print "Files with same name and different file-endings.\n";
$files->iter_sort(by_str, sub($k,$v) {
    printf "= %d files\n", $v->length;
    $v->iter(sub($file) { printf "+ %s\n", $file });
    say "";
});
