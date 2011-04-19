#!/usr/bin/perl

# 0-9 | 00-99 | 100-199 | 200-249 | 250-255, longest pattern first
$pat = qr!(
(25[0-5]|2[0-4]\d|1\d\d|\d\d|\d)\.
(25[0-5]|2[0-4]\d|1\d\d|\d\d|\d)\.
(25[0-5]|2[0-4]\d|1\d\d|\d\d|\d)\.
(25[0-5]|2[0-4]\d|1\d\d|\d\d|\d)
)!ox;

while (<>) {
    while (s/$pat/-/o) {
	print "$1\n"; # BUG: WILL PRINT "1.1.1.100" for 1.1.1.10000
    }
}

