#!/usr/bin/perl

# 0-9 | 10-99 | 100-199 | 200-249 | 250-255
$pat = qr!(
(\d|\d\d|1\d\d|2[0-4]\d|25[0-5])\.
(\d|\d\d|1\d\d|2[0-4]\d|25[0-5])\.
(\d|\d\d|1\d\d|2[0-4]\d|25[0-5])\.
(\d|\d\d|1\d\d|2[0-4]\d|25[0-5]) # nongreedy, RE will take shortest match
)!ox;

while (<>) {
    while (s/$pat/-/o) {
	print "$1\n"; # BUG: WILL PRINT "255.255.255.2" FOR 255.255.255.255
    }
}

