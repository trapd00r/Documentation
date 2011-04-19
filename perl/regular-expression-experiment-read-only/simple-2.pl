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
	print "$1\n";
    }
}

