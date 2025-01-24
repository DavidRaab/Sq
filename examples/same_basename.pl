#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

# I have this script in one of my folders. It usually contains 'mp4' files
# captured from my smartphone. But those video files from the smartphone
# do not have the best compression. I reencode the files and save the new
# reencoded file under the same name just with another file-ending.

# This script helps me quickly to identify which 'mp4' file is maybe already
# reencoded to a m4v file. Then i delete that file.

# Defines how many elements should be dumped in a sequence
$Sq::Dump::SEQ_AMOUNT = 1000;

my $mp4files =
    Sq->fs->children('.')
    ->keep(call 'is_file')->rx(qr/\.mp4\z/)
    ->split(qr/\./);

my $mv4files =
    Sq->fs->children('.')
    ->keep(call 'is_file')->rx(qr/\.m4v\z/)
    ->split(qr/\./);

# dump($mp4files);
# dump($mv4files);

print "Possible converted files that can be deleted.\n";
$mp4files->intersect($mv4files, \&fst)->iter(sub($tuple) {
    say ' + ', $tuple->join('.');
});

