package Sq::Io;
use 5.036;
use Sq;
use Sq::Exporter;

our $SIGNATURE = 'Sq/Sig/Io.pm';
our @EXPORT    = ();

use JSON qw/decode_json/;

# TODO: + check if url is a youtube URL?
static youtube => sub($url) {
    return Sq->sys->find_bin('yt-dlp')->match(
        Some => sub($exe) {
            return Sq->sys->capture($exe, '-J', $url)->match(
                Ok  => sub($args) {
                    my ($out, $err) = @$args;
                    return Ok(sq(decode_json(join '', @$out)));
                },
                Err => sub($args) {
                    my ($exit, $out, $err) = @$args;

                    # I just try to parse the OUT as JSON, when this succedds
                    # i consider the call sucessfull, when there still was
                    # a warning, it is printed to STDERR.
                    local $@;
                    my ($error, $ds) = (0);
                    eval {
                        $ds    = decode_json(join '', @$out);
                        $error = 1;
                    };
                    if ( $error ) {
                        # TODO: This shouldn't be here
                        if ( @$err ) {
                            warn "yt-dlp WARNINGS\n";
                            warn join('', @$err);
                        }
                        return Ok(sq $ds);
                    }
                    else {
                        return Err(join('', @$err));
                    }
                }
            )
        },
        None => sub {
            Err("Cannot find yt-dlp in PATH. Check if yt-dlp is installed.");
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