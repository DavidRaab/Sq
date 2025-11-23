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

sub env($) {
    state $split = sub($p) { Str->split(qr/:/, $p)->map(\&path) };
    my $env = hash(%ENV);
    $env->change(
        HOME            => \&path,
        PATH            => $split,
        MANPATH         => $split,
        PWD             => \&path,
        OLDPWD          => \&path,
        SHELL           => \&path,
        XDG_DATA_DIRS   => $split,
        XDG_DATA_HOME   => \&path,
        XDG_CACHE_HOME  => \&path,
        XDG_STATE_HOME  => \&path,
        XDG_CONFIG_HOME => \&path,
        XDG_CONFIG_DIRS => $split,
        XDG_RUNTIME_DIR => \&path,
    );
    return $env;
}

# Lookup $file in $PATH
static find_bin => sub ($file) {
    return env('')->{PATH}->pick(sub($folder) {
        my $bin = $folder->child($file);
        return Some($bin) if -x $bin;
        None;
    });
};

1;