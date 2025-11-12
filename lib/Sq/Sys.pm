package Sq::Sys;
use 5.036;
use Sq;
use Sq::Exporter;
use Path::Tiny qw(path);
use FindBin;
our $SIGNATURE = 'Sq/Sig/Sys.pm';
our @EXPORT    = ();

# This is a package that somehow interacts or provide information about
# the operating system.

sub dir($) {
    FindBin::again();
    return path($FindBin::Dir);
}

1;