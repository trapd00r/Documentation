#!/usr/bin/perl

# 0-9 | 10-99 | 100-199 | 200-249 | 250-255
$pat = qr!(
(\d|\d\d|1\d\d|2[0-4]\d|25[0-5])\.
(\d|\d\d|1\d\d|2[0-4]\d|25[0-5])\.
(\d|\d\d|1\d\d|2[0-4]\d|25[0-5])\.
(\d+) # GREEDY BUT NEEDS TO BE BOUNDSCHECKED
)!ox;

while (<>) {
    while (s/$pat/-/o) {
	print "$1\n" if ($5 < 256);
    }
}

