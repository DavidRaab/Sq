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
    return Sq->sys->find_bin('yt-dlp')->match(
        Some => sub($exe) {
            my $out  = qx/$exe -J $url/;
            my $data = decode_json($out);
            return sq($data);
        },
        None => sub {
            Carp::croak "Cannot find yt-dlp in PATH. Check if yt-dlp is installed";
        }
    )
};

static csv_read => sub($file) {
    require Text::CSV;
    return Seq->from_sub(sub {
        my $err = open my $fh, '<:encoding(UTF-8)', $file;
        if ( !defined $err ) {
            return sub { undef };
        }
        else {
            my $csv = Text::CSV->new({
                eol             => undef,
                skip_empty_rows => 'skip',
            });
            eval {
                $csv->header($fh, { sep_set => [ ";", ",", "|", "\t" ] });
            };
            if ( $@ ) {
                close $fh;
                return sub { undef };
            }
            else {
                return sub {
                    my $row = $csv->getline_hr($fh);
                    if ( !defined $row ) {
                        close $fh;
                        return undef;
                    }
                    return bless($row, 'Hash');
                };
            }
        }
    });
};

1;