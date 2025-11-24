package Sq::Io;
use 5.036;
use Sq;
use Sq::Exporter;

our $SIGNATURE = 'Sq/Sig/Io.pm';
our @EXPORT    = ();

use JSON qw/decode_json/;

# TODO: + check if url is a youtube URL?
#       + error handling of yt-dlp (just check if it returns a valid JSON?)
static youtube => sub($url) {
    return Sq->sys->find_bin('yt-dlp')->match(
        Some => sub($exe) {
            return Sq->sys->capture($exe, '-J', $url)->match(
                Ok  => sub($args) {
                    my ($out, $err) = @$args;
                    return sq decode_json(join '', @$out)
                },
                Err => sub($args) {
                    my ($exit, $out, $err) = @$args;
                    warn(
                        "Crappy yt-dlp does always return error code 1 even when successful and no warnings.\n"
                        . "Here is what yt-dlp sent on STDERR:\n" . join('', @$err) . "\n");
                    return sq decode_json(join '', @$out);
                }
            )
        },
        None => sub {
            Carp::croak "Cannot find yt-dlp in PATH. Check if yt-dlp is installed.";
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