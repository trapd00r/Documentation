#!/usr/bin/perl

use strict;

use Convert::Color;
use Getopt::Long;

print <<EOF;
<html>
 <body>
  <table border=1>
   <tr><th colspan=2>Name</th><th>RGB</th><th>XTerm</th></tr>
EOF

my @COL;

sub span
{
   my ( $text, $col ) = @_;

   my $hex = $col->as_rgb8->hex;

   if( $col->as_hsl->lightness < 0.5 ) {   
      return qq{<span style="background-color: #$hex; color: white">$text</span>};
   }
   else {
      return qq{<span style="background-color: #$hex">$text</span>};
   }
}

my $SORT = 0;

GetOptions(
   's|sort+' => \$SORT,
) or exit(1);

my @XTerm = map { Convert::Color->new( "xterm:$_" ) } 0 .. 255;

while( my $colname = shift @ARGV ) {
   if( $colname eq "x11:*" ) {
      require Convert::Color::X11;
      unshift @ARGV, map { "x11:$_" } sort Convert::Color::X11->colors;
      next;
   }

   my $col = Convert::Color->new( $colname );

   my $c_rgb8 = $col->as_rgb8;
   my $rgb8_hex = $c_rgb8->hex;

   my ( $r, $g, $b ) = $c_rgb8->rgb8;
   my $rgb = join ",",
      span( sprintf('%03d',$r), Convert::Color::RGB8->new( $r, 0, 0 ) ),
      span( sprintf('%03d',$g), Convert::Color::RGB8->new( 0, $g, 0 ) ),
      span( sprintf('%03d',$b), Convert::Color::RGB8->new( 0, 0, $b ) );

   my $best_xterm = $c_rgb8->as_xterm;
   my $xterm = span( $best_xterm->index, $best_xterm );

   push @COL, [ $best_xterm->index, <<"EOF" ];
    <tr><td>$colname</td><td bgcolor="#$rgb8_hex">&nbsp;&nbsp;&nbsp;</td><td>$rgb</td><td>$xterm</td></tr>
EOF

}

if( $SORT ) {
   @COL = sort { $a->[0] <=> $b->[0] } @COL;
}

print map { $_->[1] } @COL;

print <<EOF;
  </table>
 </body>
</html>
EOF
