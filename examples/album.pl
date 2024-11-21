#!/usr/bin/env perl
use v5.36;
use Data::Dumper qw(Dumper);
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

printf "Album: %s\n",  $album->dump;
printf "Update: %s\n", $update->dump;
