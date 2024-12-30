package Sq::Fs;
use 5.036;

# Opens a file as UTF-8 text
sub open_text($, $file) {
    return Seq->from_sub(sub {
        open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open: $!\n";
        return sub {
            if ( defined $fh ) {
                if (defined(my $line = <$fh>)) {
                    return $line;
                }
                else {
                    close $fh;
                    $fh = undef;
                }
            }
            return undef;
        };
    });
}

sub compare_text($, $file1, $file2) {
    return Sq::Equality::equal(
        open_text(undef, $file1),
        pen_text(undef, $file2)
    );
}

sub read_bytes($, $file, $count) {
    open my $fh, '<:raw', $file
        or return Result::Err("Could not open file '$file'\n");
    my $content;
    read $fh, $content, $count;
    return Result::Ok($content);
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
