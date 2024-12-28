package Sq::Fs;
use 5.036;

# Opens a file as UTF-8 text
sub open_text($class, $file) {
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

sub recurse($class, @paths) {
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

sub children($class, @paths) {
    require Path::Tiny;
    return Seq->new(Path::Tiny::path(@paths)->children);
}

1;
