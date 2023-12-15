package Sq::Io;
use v5.36;
use lib "../../lib";
use Sq::Collections::Seq;

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