#!/usr/bin/env perl
use v5.36;
use Sq;

sub seconds_to_str($seconds) {
    my $minutes = int ($seconds / 60);
       $seconds = $seconds - ($minutes * 60);
    sprintf "%02d:%02d", $minutes, $seconds;
}

my $album = Hash->new(
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => Array->new(
        Hash->new(title => "Wanna Be Startin’ Somethin", duration => 363),
        Hash->new(title => "Baby Be Mine",               duration => 260),
        Hash->new(title => "The Girl Is Mine",           duration => 242),
        Hash->new(title => "Thriller",                   duration => 357),
        Hash->new(title => "Beat It",                    duration => 258),
        Hash->new(title => "Billie Jean",                duration => 294),
        Hash->new(title => "Human Nature",               duration => 246),
        Hash->new(title => "P.Y.T.",                     duration => 239),
        Hash->new(title => "The Lady in My Life",        duration => 300),
    ),
    bonus  => "with\nnewline",
    opt1 => Some(10),
    opt2 => None,
    opt3 => Some([]),
    opt4 => Some({}),
    opt5 => Some([
        [qw/a b c/],
        {
            foo => [
                Some(1), Some(2), Some({
                    what => [qw/cool and blue/]
                })
            ]
        }
    ]),
    opt6 => Some("text"),
);

my $update =
    $album->withf(tracks => sub($tracks) {
        $tracks->map(sub($track) {
            $track->withf(duration => sub($dur) {
                Hash->new(
                    seconds   => $dur,
                    as_string => seconds_to_str($dur),
                );
            });
        });
    });

printf "Album:\n%s\n",  $album->dump();
printf "Update:\n%s\n", $update->dump(100);
