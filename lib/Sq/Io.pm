package Sq::Io;
use v5.36;

# Here will be most I/O stuff for reading/writing files and going through file-system.
# Maybe also IO::Socket and network?

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

1;