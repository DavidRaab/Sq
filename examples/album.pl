#!/usr/bin/env perl
use v5.36;
use Sq;

sub seconds_to_str($seconds) {
    my $minutes = int ($seconds / 60);
       $seconds = $seconds - ($minutes * 60);
    sprintf "%02d:%02d", $minutes, $seconds;
}

my $album = sq {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => [
        {title => "Wanna Be Startin’ Somethin", duration => 363},
        {title => "Baby Be Mine",               duration => 260},
        {title => "The Girl Is Mine",           duration => 242},
        {title => "Thriller",                   duration => 357},
        {title => "Beat It",                    duration => 258},
        {title => "Billie Jean",                duration => 294},
        {title => "Human Nature",               duration => 246},
        {title => "P.Y.T.",                     duration => 239},
        {title => "The Lady in My Life",        duration => 300},
    ],
};

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

printf "Album:\n%s\n",  $album->dump;
printf "Update:\n%s\n", $update->dump;
