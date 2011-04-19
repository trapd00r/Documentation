#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2009,2010 -- leonerd@leonerd.org.uk

package Convert::Color::XTerm;

use strict;
use warnings;
use base qw( Convert::Color::RGB8 );

__PACKAGE__->register_color_space( 'xterm' );

use Carp;

our $VERSION = '0.05';

=head1 NAME

C<Convert::Color::XTerm> - indexed colors used by XTerm

=head1 SYNOPSIS

Directly:

 use Convert::Color::XTerm;

 my $red = Convert::Color::XTerm->new( 1 );

Via L<Convert::Color>:

 use Convert::Color;

 my $cyan = Convert::Color->new( 'xterm:14' );

=head1 DESCRIPTION

This subclass of L<Convert::Color::RGB8> provides lookup of the colors that 
F<xterm> uses by default. Note that the module is not intelligent enough to
actually parse the XTerm configuration on a machine, nor to query a running
terminal for its actual colors. It simply implements the colors that are
present as defaults in the XTerm source code.

It implements the complete 256-color model in XTerm. This range consists of:

=over 4

=item *

0-7: The basic VGA colors, dark intensity. 7 is a "dark" white, i.e. a light
grey.

=item *

8-15: The basic VGA colors, light intensity. 8 represents a "light" black,
i.e. a dark grey.

=item *

16-231: A 6x6x6 RGB color cube.

=item *

232-255: 24 greyscale ramp.

=back

=cut

my @color;

sub _init_colors
{
   # The first 16 colors are dark and light versions of the basic 8 VGA colors.
   # XTerm itself pulls these from the X11 database, except for light blue.
   # These color names from xterm's charproc.c

   my @colnames;

   if( eval { require Convert::Color::X11; Convert::Color::X11->colors } ) {
      @colnames = (qw(
         x11:black   x11:red3     x11:green3 x11:yellow3
         x11:blue2   x11:magenta3 x11:cyan3  x11:gray90
         x11:gray50  x11:red      x11:green  x11:yellow
         rgb8:5C5CFF x11:magenta  x11:cyan   x11:white
      ));
   }
   else {
      @colnames = (qw(
         rgb8:000000 rgb8:cd0000 rgb8:00cd00 rgb8:cdcd00
         rgb8:0000ee rgb8:cd00cd rgb8:00cdcd rgb8:e5e5e5
         rgb8:7f7f7f rgb8:ff0000 rgb8:00ff00 rgb8:ffff00
         rgb8:5c5cff rgb8:ff00ff rgb8:00ffff rgb8:ffffff
      ));
   }

   foreach my $index ( 0 .. $#colnames ) 
   {
      my $c_tmp = Convert::Color->new( $colnames[$index] );
      $color[$index] = __PACKAGE__->SUPER::new( $c_tmp->as_rgb8->rgb8 );
      $color[$index]->[3] = $index;
   }

   # These descriptions and formulae from xterm's 256colres.pl

   # Next is a 6x6x6 color cube, with an attempt at a gamma correction
   foreach my $red ( 0 .. 5 ) {
      foreach my $green ( 0 .. 5 ) {
         foreach my $blue ( 0 .. 5 ) {
            my $index = 16 + ($red*36) + ($green*6) + $blue;

            $color[$index] = __PACKAGE__->SUPER::new(
               map { $_ ? $_*40 + 55 : 0 } ( $red, $green, $blue )
            );
            $color[$index]->[3] = $index;
         }
      }
   }

   # Finally a 24-level greyscale ramp
   foreach my $grey ( 0 .. 23 ) {
      my $index = 232 + $grey;
      my $whiteness = $grey*10 + 8;

      $color[$index] = __PACKAGE__->SUPER::new( $whiteness, $whiteness, $whiteness );
      $color[$index]->[3] = $index;
   }
}

__PACKAGE__->register_palette(
   enumerate_once => sub {
      @color or _init_colors;
      @color
   },
);

=head1 CONSTRUCTOR

=cut

=head2 $color = Convert::Color::XTerm->new( $index )

Returns a new object to represent the color at that index.

=cut

sub new
{
   my $class = shift;

   if( @_ == 1 ) {
      my $index = $_[0];

      @color or _init_colors;

      $index >= 0 and $index < 256 or
         croak "No such XTerm color at index '$index'";

      return $color[$index];
   }
   else {
      croak "usage: Convert::Color::XTerm->new( INDEX )";
   }
}

=head1 METHODS

=cut

=head2 $index = $color->index

The index of the XTerm color.

=cut

sub index
{
   my $self = shift;
   return $self->[3];
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<Convert::Color> - color space conversions

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>
