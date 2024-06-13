package Hash;
use 5.036;

sub from_array($, $array, $f) {
    my $h = Hash->new;
    my $stop = @$array;
    for (my $i=0; $i < $stop; $i++) {
        my ($k,$v) = $f->($i,$array->[$i]);
        $h->{$k} = $v;
    }
    return $h;
}

sub to_array($hash, $f) {
    my $a = Array->new;
    while ( my ($key, $value) = each %$hash ) {
        CORE::push @$a, $f->($key, $value);
    }
    return $a;
}

1;