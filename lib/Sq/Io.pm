package Sq::Io;
use 5.036;
use Sq;
use Sq::Exporter;
our $SIGNATURE = 'Sq/Sig/Io.pm';
our @EXPORT    = ();

use JSON qw/decode_json/;

# TODO: + Check if yt-dlp is installed / throw error if not
#       + build function to check/scan for binary files in OS
#       + check if url is a youtube URL?
#       + safer way to run a program and get output of program
static youtube => sub($url) {
    my $out  = qx/yt-dlp -J $url/;
    my $data = decode_json($out);
    return sq($data);
};

1;