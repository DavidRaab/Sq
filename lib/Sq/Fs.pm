package Sq::Fs;
use 5.036;
use Sq;

# Opens a file as UTF-8 text
sub read_text($, @path) {
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
}

sub read_raw($, $size, @path) {
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
}

# TODO: reads a gziped file transparent as text
sub read_zip() { ... }


sub compare_text($, $file1, $file2) {
    return equal(
        read_text(undef, $file1),
        read_text(undef, $file2)
    );
}

sub read_bytes($, $file, $count) {
    open my $fh, '<:raw', $file
        or return Err("Could not open file '$file': $!");
    my $content;
    my $read = read $fh, $content, $count;
    return Err("Error reading from '$file': $!") if !defined $read;
    return Ok($content);
}

sub make_link($, $source, $destination) {
    require Path::Tiny;

    $source      = Path::Tiny::path($source)->absolute;
    $destination = Path::Tiny::path($destination);
    my $cwd = Path::Tiny->cwd;

    chdir($destination->parent)
        or die "Cannot chdir: $!\n";
    symlink($source->relative, $destination->basename)
        or die "Cannot create symlink: $!\n";

    chdir($cwd);
}

sub recurse($, @paths) {
    require Path::Tiny;
    Seq->from_sub(sub {
        my $it = Path::Tiny::path(@paths)->iterator({
            recurse         => 1,
            follow_symlinks => 1,
        });

        my $path;
        return sub { $it->() }
    });
}

sub children($, @paths) {
    require Path::Tiny;
    return Seq->new(Path::Tiny::path(@paths)->children);
}

1;
