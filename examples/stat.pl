#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

sub mystat($file) {
    state $to_hash = record(qw/dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks/);
    state $to_date = sub($str) { scalar localtime $str };
    return Some(stat $file)->map($to_hash)->map(sub($stat) {
        $stat->{ctime_date} = $to_date->($stat->{ctime});
        $stat->{mtime_date} = $to_date->($stat->{mtime});
        $stat->{atime_date} = $to_date->($stat->{atime});
        $stat
    });
}

dump(mystat 'stat.pl');
