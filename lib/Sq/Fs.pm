package Sq::Fs;
use 5.036;
use Sq;

# Opens a file as UTF-8 text
static read_text => sub(@path) {
    require Path::Tiny;
    my $file = Path::Tiny::path(@path);
    return Seq->from_sub(sub {
        open my $fh, '<:encoding(UTF-8)', $file;
        if ( !defined $fh ) {
            return sub { undef }
        }
        else {
            my $line;
            return sub {
                $line = <$fh>;
                return $line if defined $line;
                close $fh;
                undef $fh;
            };
        }
    });
};

# reads a text file that is compressed as .gz
static read_text_gz => sub(@path) {
    require PerlIO::gzip;
    require Path::Tiny;
    my $file = Path::Tiny::path(@path);
    return Seq->from_sub(sub {
        open my $fh, '<:raw:gzip:encoding(UTF-8)', $file;
        if ( !defined $fh ) {
            return sub { undef }
        }
        else {
            my $line;
            return sub {
                $line = <$fh>;
                return $line if defined $line;
                close $fh;
                undef $fh;
            };
        }
    });
};

static read_raw => sub($size, @path) {
    require Path::Tiny;
    my $file = Path::Tiny::path(@path);
    return Seq->from_sub(sub {
        open my $fh, '<:raw', $file;
        if ( !defined $fh ) {
            return sub { undef }
        }
        else {
            return sub {
                my $byte;
                if ( read $fh, $byte, $size ) {
                    return $byte;
                }
                close $fh;
                undef $fh;
            };
        }
    });
};

# TODO: Make it work that it also works with a `state` variable. `static`
#       has one problem. When signature are loaded, you must specifiy
#       all needed arguments. So just calling the function without any
#       argument makes it return an type-error. So `static` and `signature`
#       must be extended that his works better. Otherwise `static` is useless
#       with signatures.
{
    my $read_text = read_text();
    static compare_text => sub($file1, $file2) {
        return equal(
            $read_text->($file1),
            $read_text->($file2)
        );
    };
}

static read_bytes => sub($size, @path) {
    require Path::Tiny;
    my $file = Path::Tiny::path(@path);

    open my $fh, '<:raw', $file
        or return Err("Could not open file '$file': $!");
    my $content;
    my $read = read $fh, $content, $size;
    return Err("Error reading from '$file': $!") if !defined $read;
    return Ok($content);
};

static make_link => sub($source, $destination) {
    require Path::Tiny;

    $source      = Path::Tiny::path($source)->absolute;
    $destination = Path::Tiny::path($destination);
    my $cwd = Path::Tiny->cwd;

    chdir($destination->parent)
        or die "Cannot chdir: $!\n";
    symlink($source->relative, $destination->basename)
        or die "Cannot create symlink: $!\n";

    chdir($cwd);
    return;
};

static recurse => sub(@paths) {
    require Path::Tiny;
    Seq->from_sub(sub {
        my $it = Path::Tiny::path(@paths)->iterator({
            recurse         => 1,
            follow_symlinks => 1,
        });

        my $path;
        return sub { $it->() }
    });
};

static children => sub(@paths) {
    require Path::Tiny;
    return Seq->new(Path::Tiny::path(@paths)->children);
};

static sha512 => sub(@paths) {
    require Path::Tiny;
    my $file = Path::Tiny::path(@paths);
    my $err = open my $fh, '<:raw', $file;
    return Err("Could not open '$file': $!") if !defined $err;

    require Digest::SHA;
    my $sha  = Digest::SHA->new('sha512');
    $sha->addfile($fh);

    return Ok($sha->hexdigest);
};

1;
