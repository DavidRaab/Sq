package Sq::Fs;
use 5.036;
use Sq;
use Path::Tiny qw(path);
use Sq::Exporter;
our $SIGNATURE = 'Sq/Sig/Fs.pm';
our @EXPORT    = ();

# Opens a file as UTF-8 text
static read_text => sub(@path) {
    my $file = path(@path);
    return Seq->from_sub(sub {
        if ( -f $file ) {
            my $err = open my $fh, '<', $file;
            if ( !defined $err ) {
                return sub { undef }
            }
            else {
                my $line;
                return sub {
                    $line = <$fh>;
                    if ( defined $line ) {
                        if ( utf8::decode($line) ) {
                            chomp $line;
                            return $line;
                        }
                        else {
                            warn "read_text: '$file' does not contain valid utf-8. Abort reading from file.\n";
                            close $fh;
                            undef $fh;
                            return undef;
                        }
                    }
                    close $fh;
                    undef $fh;
                };
            }
        }
        else {
            return sub { undef };
        }
    });
};

my $path = type [or => ['str'], [ref => 'Path::Tiny']];
static write_text => with_dispatch(
    type [tuple => $path, ['str']] => sub($file,$content) {
        # We want to write utf-8 but still open as raw because the encoding
        # is done manually. Perl string are either raw (Latin1 ISO-8859-1)
        # or Unicode (UTF-8). When a user provides a raw string
        # then no additionaly encoding to UTF-8 is done, and we assume
        # the user already did an Encode::encode('UTF-8', $str) or similar
        # call. Without this handling we would get double encoded output.
        my $err = open my $fh, '>:raw', $file;
        if ( !defined $err ) {
            return Err({op => 'open', file => $file, message => $!});
        }

        # when string is in unicode, we encode it to utf8 before printing
        if ( utf8::is_utf8($content) ) {
            utf8::encode($content);
            $err = print {$fh} $content;
        }
        # string without unicode (utf8) flag is printed as-is. We assume
        # the user already encoded the string.
        else {
            $err = print {$fh} $content;
        }
        # check print for errors
        if ( !$err ) {
            close $fh;
            return Err({op => 'print', file => $file, message => $!});
        }

        # close file
        $err = close $fh;
        if ( !$err ) {
            return Err({op => 'close', file => $file, message => $!});
        }

        return Ok(1);
    },
    type [tuple => $path, [array => [of => ['str']]]] => sub($file,$aoa) {
        # open file
        my $err = open my $fh, '>:raw', $file;
        if ( !defined $err ) {
            return Err({op => 'open', file => $file, message => $!});
        }

        # write file
        for ( @$aoa ) {
            # we need a copy, not an alias. Otherwise the function would
            # change encoding of the string in the array.
            my $line = $_;
            if ( utf8::is_utf8($line) ) {
                utf8::encode($line);
                $err = print {$fh} $line, "\n";
            }
            else {
                $err = print {$fh} $line, "\n";
            }
            if ( !$err ) {
                close $fh;
                return Err({op => 'print', file => $file, message => $!});
            }
        }

        # close file
        $err = close $fh;
        if ( !$err ) {
            return Err({op => 'close', file => $file, message => $!});
        }

        return Ok(1);
    },
    type [tuple => $path, ['seq']] => sub($file, $seq) {
        # open file
        my $err = open my $fh, '>:raw', $file;
        if ( !defined $err ) {
            return Err({op => 'open', file => $file, message => $!});
        }

        # write file
        $seq->iter(sub($line) {
            if ( utf8::is_utf8($line) ) {
                utf8::encode($line);
                $err = print {$fh} $line, "\n";
            }
            else {
                $err = print {$fh} $line, "\n";
            }
            if ( !$err ) {
                close $fh;
                return Err({op => 'print', file => $file, message => $!});
            }
        });

        # close file
        $err = close $fh;
        if ( !$err ) {
            return Err({op => 'close', file => $file, message => $!});
        }

        return Ok(1);
    },
);

static write_text_gz => with_dispatch(
    type [tuple => $path, ['str']] => sub($file,$content) {
        # We want to write utf-8 but still open as raw because the encoding
        # is done manually. Perl string are either raw (Latin1 ISO-8859-1)
        # or Unicode (UTF-8). When a user provides a raw string
        # then no additionaly encoding to UTF-8 is done, and we assume
        # the user already did an Encode::encode('UTF-8', $str) or similar
        # call. Without this handling we would get double encoded output.
        my $err = open my $fh, '>:gzip', $file;
        if ( !defined $err ) {
            return Err({op => 'open', file => $file, message => $!});
        }

        # when string is in unicode, we encode it to utf8 before printing
        if ( utf8::is_utf8($content) ) {
            utf8::encode($content);
            $err = print {$fh} $content;
        }
        # string without unicode (utf8) flag is printed as-is. We assume
        # the user already encoded the string.
        else {
            $err = print {$fh} $content;
        }
        # check print for errors
        if ( !$err ) {
            close $fh;
            return Err({op => 'print', file => $file, message => $!});
        }

        # close file
        $err = close $fh;
        if ( !$err ) {
            return Err({op => 'close', file => $file, message => $!});
        }

        return Ok(1);
    },
    type [tuple => $path, [array => [of => ['str']]]] => sub($file,$aoa) {
        # open file
        my $err = open my $fh, '>:gzip', $file;
        if ( !defined $err ) {
            return Err({op => 'open', file => $file, message => $!});
        }

        # write file
        for ( @$aoa ) {
            # we need a copy, not an alias. Otherwise the function would
            # change encoding of the string in the array.
            my $line = $_;
            if ( utf8::is_utf8($line) ) {
                utf8::encode($line);
                $err = print {$fh} $line, "\n";
            }
            else {
                $err = print {$fh} $line, "\n";
            }
            if ( !$err ) {
                close $fh;
                return Err({op => 'print', file => $file, message => $!});
            }
        }

        # close file
        $err = close $fh;
        if ( !$err ) {
            return Err({op => 'close', file => $file, message => $!});
        }

        return Ok(1);
    },
    type [tuple => $path, ['seq']] => sub($file, $seq) {
        # open file
        my $err = open my $fh, '>:gzip', $file;
        if ( !defined $err ) {
            return Err({op => 'open', file => $file, message => $!});
        }

        # write file
        $seq->iter(sub($line) {
            if ( utf8::is_utf8($line) ) {
                utf8::encode($line);
                $err = print {$fh} $line, "\n";
            }
            else {
                $err = print {$fh} $line, "\n";
            }
            if ( !$err ) {
                close $fh;
                return Err({op => 'print', file => $file, message => $!});
            }
        });

        # close file
        $err = close $fh;
        if ( !$err ) {
            return Err({op => 'close', file => $file, message => $!});
        }

        return Ok(1);
    },
);

# reads a text file that is compressed as .gz
static read_text_gz => sub(@path) {
    require PerlIO::gzip;
    my $file = path(@path);
    return Seq->from_sub(sub {
        my $err = open my $fh, '<:raw:gzip:encoding(UTF-8)', $file;
        if ( !defined $err ) {
            return sub { undef }
        }
        else {
            my $line;
            return sub {
                $line = <$fh>;
                if ( defined $line ) {
                    chomp $line;
                    return $line;
                }
                close $fh;
                undef $fh;
            };
        }
    });
};

static read_raw => sub($size, @path) {
    my $file = path(@path);
    return Seq->from_sub(sub {
        my $err = open my $fh, '<:raw', $file;
        if ( !defined $err ) {
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

static compare_text => sub($file1, $file2) {
    state $read_text = read_text();
    return equal(
        $read_text->($file1),
        $read_text->($file2)
    );
};

static read_bytes => sub($size, @path) {
    my $file = path(@path);

    open my $fh, '<:raw', $file
        or return Err("Could not open file '$file': $!");
    my $content;
    my $read = read $fh, $content, $size;
    return Err("Error reading from '$file': $!") if !defined $read;
    return Ok($content);
};

static make_link => sub($source, $destination) {
    $source      = path($source)->absolute;
    $destination = path($destination);
    my $cwd      = Path::Tiny->cwd;

    chdir($destination->parent)
        or die "Cannot chdir: $!\n";
    symlink($source->relative, $destination->basename)
        or die "Cannot create symlink: $!\n";

    chdir($cwd);
    return;
};

static recurse => sub(@paths) {
    Seq->from_sub(sub {
        my $it = path(@paths)->iterator({
            recurse         => 1,
            follow_symlinks => 1,
        });

        my $path;
        return sub { $it->() }
    });
};

static children => sub(@paths) {
    return seq { path(@paths)->children };
};

static sha512 => sub(@paths) {
    my $file = path(@paths);
    my $err  = open my $fh, '<:raw', $file;
    return Err("Could not open '$file': $!") if !defined $err;

    require Digest::SHA;
    my $sha = Digest::SHA->new('sha512');
    $sha->addfile($fh);

    return Ok($sha->hexdigest);
};

static search_upwards => sub($entry) {
    my $current = Path::Tiny->cwd;

    CHECK:
    my $fs = $current->child($entry);
    if ( -e $fs ) {
        return Some($fs);
    }
    elsif ( $current eq '/' ) {
        return None;
    }
    else {
        $current = $current->parent;
        goto CHECK;
    }
};

1;
