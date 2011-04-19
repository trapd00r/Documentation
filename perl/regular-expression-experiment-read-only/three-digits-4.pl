#!/usr/bin/perl

# match 0-999
$pat = qr!(
(\d{1,3})\.
(\d{1,3})\.
(\d{1,3})\.
(\d{1,3})\b # ANCHOR TO WORD BOUNDARY
)!ox;

while (<>) {
    while (s/$pat/-/o) {
	print "$1\n" if (($2 < 256) and ($3 < 256) and ($4 < 256) and ($5 < 256));
    }
}

