#!/usr/bin/perl

use Huffman;

my $file = '/tmp/htest.out';
open FILE, "> $file" 
  or die "Couldn't open file $file for writing: $!; aborting";

$/ = undef;
$_ = <>;
my @symbols = split /(\W)/;
print STDERR "Histogramming.\n";
my $hist = Huffman::histogram(\@symbols);
print STDERR "Building code table.\n";
my $codes = Huffman::tabulate($hist);
print STDERR "Writing code table.\n";
Huffman::save_code_table(*FILE, $codes);
print STDERR "Writing compressed data.\n";
Huffman::encode(*FILE, $codes, \@symbols);
# print FILE $codes;
close FILE;
print STDERR "Encoding finished.\n";

open FILE, "< $file" 
  or die "Couldn't open file `$file' for reading: $!; aborting";
print STDERR "Reading code table.\n";
my $codes = Huffman::load_code_table(*FILE);
#  my $cr = Huffman::codetab_reverse($codes);
print STDERR "Reading compressed data.\n";
my $coded_data = <FILE>;
print STDERR "Uncompressing.\n";
my $text = Huffman::decode($codes, $coded_data);
print $text;
1;
1;
1;

