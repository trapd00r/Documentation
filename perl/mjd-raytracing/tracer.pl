#!/usr/bin/perl
# -*- mode: perl; perl-indent-level: 2 -*-

# 
# Simple ray tracer in Perl
# Author: Mark-Jason Dominus (mjd-perl-raytracer@plover.com)
# 
# This program is in the PUBLIC DOMAIN
#

use Carp;
use FileHandle;
STDERR->autoflush(1);
require 'getopts.pl';

# Options:
# -p position and facing of viewpoint in the form:
#     xpos,ypos,facing
#    where `facing' is 0=north, 90=east
# -X, -Y  Width and height of output, in pixels
# -d distance to `screen'
# -a range of vision angle
# -D enable debug mode
# -G grayscale mode
&Getopts('DP:X:Y:d:a:G');
$DEBUG = $opt_D;

$pi = 3.1415926535897932386;
$FAR_AWAY = 1_000_000_000;	# Nothing is this far away.

# Get coordinates of viewpoint, and facing
# use command-line argument if available; default to
# 0,0 and north-facing if not.
($vx, $vy, $vf) = (split(/,/, $opt_P), 0, 0, 0);
# Normalize $vf to internal compass:  Radians, with 0 meaning east and
# increasing counterclockwise
$vf = (90 - $vf) * $pi / 180;
$v = [ $vx, $vy ];

# Half of range vision angle
$va = ($opt_a*$pi/360) || ($pi / 4);
croak "Bad viewing angle---use number between 0 and 180.\n"
    unless $va > 0 && $va < $pi / 2;

# Get dimensions of output.
$X = $opt_x || 320;
$Y = $opt_y || 200;

# Distance to screen
$D = $opt_d || 1;

my $infile = shift;
die "Usage: $0 infile [outfile]\n"
    unless defined $infile;

my $outfile = shift;
if (defined $outfile) {
  open(OUT, "> $outfile") 
      or die "Couldn't open output file `$outfile' for writing: $!; aborting";
  $outh = \*OUT;
} else {
  $outh = \*STDOUT;
}


open (I, "< $infile") 
    or die "Couldn't open input file `$infile': $!; aborting";
while (<I>)  {
  s/\#.*//;
  next unless /\S/;
  my @coords = split;
  unless (@coords == 5) {
    my $n = @coords;
    warn "Line $. of input file `$infile' has $n fields instead of 5.  Skipping.\n";
    next;
  }
  my ($x1, $y1, $x2, $y2, $c) = @coords;
  push @lines, [Segment([$x1, $y1], [$x2, $y2]), 
		{ID => $., 
		 COLOR => HueToRGB($c),
		 HEIGHT => 1,
		 MAX_INTENSITY => -$FAR_AWAY, 
		 MIN_INTENSITY => $FAR_AWAY, 
		 MAX_DISTANCE => -$FAR_AWAY, 
		 MIN_DISTANCE => $FAR_AWAY, 
		}
	       ];
}
close I;

#
# This would be a good place to preprocess the @lines list
# so that the closest lines come first.
#

{
  # Unit vector in the direction you are facing
  my $uf = UnitVector($vf);
  # Midpoint of screen 
  my $sm = VectorSum($v, ScalarProd($D, $uf));

  # Left and right endpoints of screen
  $sl = VectorSum($sm, ScalarProd($D*tan($va),  Left($uf)));
  $sr = VectorSum($sm, ScalarProd($D*tan($va), Right($uf)));
}

# Create the canvas:
{
  my @c = ("\xff" x (3*$X)) x $Y;
  $canvas = \@c;
}

# Main loop
# $p is the pixel of the screen that we're going to draw now
for ($p=0; $p < $X; $p++) {
  print STDERR "." if ($p+1) % 50 == 0; 
  print STDERR "$p\n" if $DEBUG;

  # Point of the screen that we're shooting through
  my $sp = Partway($sl, $sr, $p/($X-1));
  my $dsp = Distance($sp, $v);	# Distance to $sp
  my $los = Ray($v, $sp);

  my $closest_line_distance = $FAR_AWAY;
  my ($closest_line, $closest_line_intersection);
  
  # And what do we see in *this* direction?
  foreach $line (@lines) {
    my ($segment, $lineinfo) = @$line;
    my $intersection = TrueIntersection($los, $segment);
    next unless defined $intersection;
    my $d = Distance($intersection->[0], $v);
    next unless $d < $closest_line_distance;
    if ($d < $dsp) {
      # Clip walls inside the viewplane
      warn "Line $line->[2]{ID} is inside the viewplane at col. $p; clipping.\n"
	unless $clipped{$line->[2]{ID}}++;
      next;
    }
    $closest_line_distance = $d;
    $closest_line = $line;
    $closest_line_intersection = $intersection->[0];
  }

  # If we didn't see anything, don't render it.
  next unless $closest_line;
  next unless $closest_line_distance < $FAR_AWAY;

  die "Closest line distance negative ($closest_line_distance) at p=$p; aborting" 
      if $closest_line_distance < 0;

  # Compute the height of the thing we see, in pixels.
  # Height is inversely proportional to distance. 
  # The screen has height 1; an object twice as far as the screen has
  # height 1/2, etc.
#  my $h = $Y * $D / $closest_line_distance;
  # But actually it looks funny if we do this because we don't usually
  # see things long enuogh to exhibit this behavior.
  # BUG HERE - Don't use Y coord; use distance in direction 
  # perpendicular to screen.
  # NO, that's the same mistake you made in 1995.
  # George pointed out that you need to make h = D / d,
  # where D is the distance to the wall, and d is the distance to 
  # the screen. (screen = `viewplane')
#  my $h = $Y * $D / ($closest_line_intersection->[1]);
#   my $h = $Y * $D / DotProd(VectorSum($closest_line_intersection,
# 				      Minus($v)),
# 			    UnitVector(RayDirection($los))
# 			    );
  my ($segment, $lineinfo) = @$closest_line;

  my $h = $Y * $dsp / $closest_line_distance; 

  # Compute the color of the thing we see.
  my ($r, $g, $b) = @{$lineinfo->{COLOR}};
  my $intensity = 2 / sqrt($closest_line_distance);
  if ($DEBUG) {
    $lineinfo->{MAX_INTENSITY} = $intensity
      if $lineinfo->{MAX_INTENSITY} < $intensity;
    $lineinfo->{MIN_INTENSITY} = $intensity
      if $lineinfo->{MIN_INTENSITY} > $intensity;
    $lineinfo->{MAX_DISTANCE} = $closest_line_distance
      if $lineinfo->{MAX_DISTANCE} < $closest_line_distance;
    $lineinfo->{MIN_DISTANCE} = $closest_line_distance
      if $lineinfo->{MIN_DISTANCE} > $closest_line_distance;
    $lineinfo->{MAX_HEIGHT} = $h
      if $lineinfo->{MAX_HEIGHT} < $h;
    $lineinfo->{MIN_HEIGHT} = $h
      if $lineinfo->{MIN_HEIGHT} > $h;
  }
  my $colorstr;
  if ($previous_closest_line ne $lineinfo->{ID}) {
    $colorstr = "\x0\x0\x0";
  } else {
    for ($r, $g, $b) {
      my $i = $_ * $intensity * 256;
      if ($i < 0) {
	$i = 0;
      } elsif ($i > 255) {
	$i = 255;
      }
      $colorstr .= chr($i);
    }
  }

  my $bot = $Y/2 + $h/2;
  my $top = $bot - $lineinfo->{HEIGHT} * $Y * $dsp / $closest_line_distance;

  Render($canvas, $p, $top, $bot, $colorstr);
  
  $previous_closest_line = $lineinfo->{ID};
}

print STDERR "\n";
if ($DEBUG) {
  foreach $line (@lines) {
    my $lineinfo = $line->[1];
    print STDERR sprintf "%02d %2.2f %2.2f %2.2f %2.2f %2.2f %2.2f\n",
      @{$lineinfo}{qw(ID MIN_INTENSITY MAX_INTENSITY MIN_DISTANCE MAX_DISTANCE MIN_HEIGHT MAX_HEIGHT)};
  }
}

DisplayCanvas($outh, $canvas);

################################################################
#
# Graphics subroutines
#
################################################################

# Convert my totally arbitrary hue number [0..360)
# to a set of RGB values.
sub HueToRGB {
  my $hue = shift;
  
  # Handle out of range.  $hue is now in [0, 360).
  $hue = $hue - 360 * int($hue / 360);  

  my ($r, $g, $b);
  if ($hue < 120) {		# Red-yellow-green area
    $r = (120 - $hue) / 120;
    $g = $hue         / 120;
    $b = 0;
  } elsif ($hue < 240) {	# Green-cyan-blue area
    $r = 0;
    $g = (240 - $hue) / 120;
    $b = ($hue - 120) / 120;
  } else {			# Blue-magenta-red area
    $r = ($hue - 240) / 120;
    $g = 0;
    $b = (360 - $hue) / 120;
  }

  print STDERR "Hue $hue => ($r, $g, $b)\n";
  if ($opt_G) {			# Convert to grayscale
    $r = $g = $b = 0.30 * $r + 0.59 * $g + 0.11 * $b;
  }
  [$r, $g, $b];
}

# Arguments:
#  Canvas
#  column number
#  height of object (pixels)
#  Color of object (3-char string)
sub Render {
  my $c = shift;
  my $n = shift;
  my $top = shift;
  my $bot = shift;
  my $color = shift;
  my $y;

  $top = 0 if $top < 0;
  $bot = $Y - 1 if $bot >= $Y;

  if ($color eq "\xff\xff\xff") {
    warn "At column $n the color is white.\n";
  }

  for ($y = $top; $y <= $bot; $y++) {
    substr($c->[$y], 3*$n, 3) = $color;
  }
}

# Print out the canvas in PPM format to the filehandle specified
sub DisplayCanvas {
  my $fh = shift;
  my $canvas = shift;

  print $fh "P6\n$X $Y\n255\n";

  print $fh @$canvas;
}

################################################################
#
# Utility subroutines
#
################################################################

# tangent function
sub tan {
  sin($_[0]) / cos($_[0]);
}

# Direction of a ray
sub RayDirection {
  my $l = shift;
  my $type = $l->[2];
  croak "Asked for direction of a `$type' which should have been a RAY.\n"
      unless $type eq RAY;
  my $endpoint = $l->[0];
  my $farpoint = $l->[1];
  my $xd = $farpoint->[0] - $endpoint->[0];
  my $yd = $farpoint->[1] - $endpoint->[1];
  my $rad = atan2($yd, $xd);
  $rad += 2*$pi if $rad < 0;
  $rad;
}

# Return the unit vector in a certain direction
sub UnitVector {
  my $d = shift;
  [ cos $d, sin $d ];
}

# Rotate a vector a quarter-turn counterclockwise
sub Left {
  my $v = shift;
  [ - $v->[1], $v->[0] ];
}

# Rotate a vector a quarter-turn clockwise
sub Right {
  my $v = shift;
  [ $v->[1], - $v->[0] ];
}

# Rotate a vector a half turn
sub Minus {
  my $v = shift;
  [ - $v->[0], - $v->[1] ];
}

# Given two points, and a fraction t find the point that is `t' of
# the way between the two points
sub Partway {
  my $p1 = shift;
  my $p2 = shift;
  my $t = shift;
  [($p1->[0] * (1-$t)) + ($p2->[0] * $t),
   ($p1->[1] * (1-$t)) + ($p2->[1] * $t)
   ];
}

# Multiply a vector by a scalar
sub ScalarProd {
  my $s = shift;
  my $v = shift;
  [ $v->[0] * $s, $v->[1] * $s ];
}

# Dot product of two vectors
sub DotProd {
  my $v1 = shift;
  my $v2 = shift;
  $v1->[0] * $v2->[0] + $v1->[1] * $v2->[1];
}

# Sum of vectors
sub VectorSum {
  my ($x, $y) = (0, 0);
  for (@_) {
    $x += $_->[0];
    $y += $_->[1];
  }
  [ $x, $y ];
}

# Build a ray.  
# Accept two points as arguments; first is endpoint, 
# second is in the direction of the ray.
sub Ray {
  [ $_[0], $_[1], RAY ];
}

# Build a line.  
# Accept two points as arguments; the line passes through these
sub Line {
  [ $_[0], $_[1], LINE ];
}


# Build a line segment.  
# Accept two points as arguments; these are the endpoints
sub Segment {
  [ $_[0], $_[1], SEGMENT ];
}


# Given a line and a point, find the parameter of the point if it
# lies on the line
sub ParamOf {
  my $p = shift;
  my $l = shift;
  my $l1 = $l->[0];
  my $l2 = $l->[1];
  my $v = VectorSum($l2, Minus($l1));

  croak "Line [($l1->[0],$l1->[1]), ($l2->[0],$l2->[1])] is ill-defined.  Aborting" 
      if IsZero($v);
  # Line is now a ray defined by $l1 and $v.
  if ($v->[0] == 0) {		# Vertical line
    return undef unless $p->[0] == $l1->[0];
    ($p->[1] - $l1->[1])/ $v->[1];
  } elsif ($v->[1] == 0) {	# Horizontal line
    return undef unless $p->[1] == $l1->[1];
    ($p->[0] - $l1->[0])/ $v->[0];
  } else {			# Diagonal line
    my $tx = ($p->[0] - $l1->[0])/ $v->[0];
    my $ty = ($p->[1] - $l1->[1])/ $v->[1];
    return undef unless $tx == $ty;
    $tx;
  }
}

# Figure out if two lines intersect.
sub TrueIntersection {
  my @ret = my ($INTERSECTION, $t1, $t2) = Intersection(@_);
  return undef unless ParamIsGood($t1, $_[0]);
  return undef unless ParamIsGood($t2, $_[1]);
  \@ret;
}

# Figure out if two lines would intersect if infinitely extended.
# Return undef if there is no intersection.
# Otherwise, return ([X, Y], T1, T2).
# [X, Y] is the intersection point.
# T1 and T2 are the position of the intersection point
# on the first and second lines, respectively.
sub Intersection {
  my $l1 = shift;
  my $l2 = shift;
  my ($bp1, $op1) = @$l1;
  my ($bp2, $op2) = @$l2;
  my $v1 = VectorSum($op1, Minus($bp1));
  my $v2 = VectorSum($op2, Minus($bp2));
  my ($x1, $y1) = @$v1;
  my ($x2, $y2) = @$v2;

  my $DEN = $x1 * $y2 - $x2 * $y1;

  # Lines are parallel.
  return undef if $DEN == 0;

  my ($bx1, $by1) = @$bp1;
  my ($bx2, $by2) = @$bp2;
  
  my $t1 = (($bx2 - $bx1) * $y2 - ($by2 - $by1) * $x2) / $DEN;
  my $t2 = (($bx2 - $bx1) * $y1 - ($by2 - $by1) * $x1) / $DEN;

  my $RESULT = VectorSum($bp1, ScalarProd($t1, $v1));
  ($RESULT, $t1, $t2);
}

# Is this a suitable parameter for this line?
sub ParamIsGood {
  my $t = shift;
  my $ln = shift;
  my $type = $ln->[2];
  return $type eq LINE
      || $type eq RAY     && $t >= 0
      || $type eq SEGMENT && $t >= 0 && $t <= 1;
}

# Distance between two points
sub Distance {
  my $p1 = shift;
  my $p2 = shift;
  my ($x1, $y1) = @$p1;
  my ($x2, $y2) = @$p2;
  sqrt(($x1-$x2)*($x1-$x2) + ($y1-$y2)*($y1-$y2));
}

# Length of a vector
sub Length {
  my $p1 = shift;
  sqrt($p1->[0]**2 + $p1->[1]**2);
}




