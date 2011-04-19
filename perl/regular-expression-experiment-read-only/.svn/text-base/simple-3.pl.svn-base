#!/usr/bin/perl

# match digits
$pat = qr!(
(\d+)\.
(\d+)\.
(\d+)\.
(\d+)
)!ox;

while (<>) {
    while (s/$pat/-/o) {
	print "$1\n" if (($2 < 256) and ($3 < 256) and ($4 < 256) and ($5 < 256));
    }
}

