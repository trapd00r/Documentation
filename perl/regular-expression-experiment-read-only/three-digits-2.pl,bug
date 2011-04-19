#!/usr/bin/perl

# match 0-999
$pat = qr!(
(\d{1,3})\.
(\d{1,3})\.
(\d{1,3})\.
(\d{1,3})
)!ox;

while (<>) {
    while (s/$pat/-/o) {
	print "$1\n";
    }
}

