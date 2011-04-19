package Term::Menu::Hierarchical;
use strict;
use warnings;
use POSIX;
use Term::Cap;
use Term::ReadKey;
require Exporter;
$|++;

our @ISA = qw(Exporter);
our @EXPORT = qw(menu);

our $VERSION = '0.01';

########################################################################################

sub menu {
	# if ($^O =~ /^(?:MSWin|VMS|dos|MacOS|os2|epoc|cygwin)/i){
	# 	# If I ever get hold of a MacOS or a Windows box, I'll try to make it work there, too.
	# 	die "Sorry, only Unix OSes are supported for now.\n";
	# }

	my $ti = new POSIX::Termios;
	$ti->getattr;
	my $ospeed = $ti->getospeed;

	my $t = Term::Cap->Tgetent({ TERM => undef, OSPEED => $ospeed||38400 });
	$t->Trequire(qw/ce cl/);
	my($max_width, $max_height) = GetTerminalSize "STDOUT";

	my $all = shift;
	die "The argument must be a hashref (arbitrary depth); exiting.\n" unless ref($all) eq 'HASH';

	my $data = _resetdata($all);

	{
		$t->Tputs("cl", 1, *STDOUT);
		if (ref($data->{content}) eq 'HASH'){
			$data = _display($data, $t, $max_width);
		}
		else {
			_more("$data->{label}\n\n$data->{content}\n", $max_width, $max_height, $t);
			$data = _resetdata($all);
		}
		redo;
	}

	sub _resetdata {
		my $d;
		$d->{content} = shift;
		$d->{label}   = 'Top';
		return $d;
	}

	sub _more {
		return unless $_[0];
		my @txt = split /\n/, shift;
		my $mw  = shift;
		my $mh  = shift;
		my $t   = shift;
		my ($idx, $line, $key) = (0, 0);
		my $maxw = $mw - 1;
		my $prompt = '[ <space|Enter>=page down  <q>=quit ]   ';
		$t->Tputs("cl", 1, *STDOUT);

		{
			if (++$line % ($mh - 1) && $idx <= $#txt){
				$txt[$idx] =~ s/^(.{$maxw}).*/$1>/ if length($txt[$idx]) > $maxw;
				print "$txt[$idx++]\n";
			}
			else {
				if ($idx >= @txt){
					print "~\n" x ($mh - ($line - 1) % $mh - 3);
				}
				else {
					$idx--;
				}
				$t->Tputs("so", 1, *STDOUT);
				$t->Tputs("md", 1, *STDOUT);
				print "\n", $prompt, ' ' x ($mw - length($prompt));
				$t->Tputs("me", 1, *STDOUT);
				$t->Tputs("se", 1, *STDOUT);
				ReadMode 4;
				1 while not defined ($key = ReadKey(-1));
				ReadMode 0;
				$t->Tputs("cl", 1, *STDOUT);
				last if defined $key && $key =~ /^q/i || $idx >= $#txt;
			}
			redo;
		}
	}

	sub _display {
		my $ref = shift;
		my $t   = shift;
		my $mw  = shift;
		# reverse-sort the lengths of all the item names, count them...
		my $num_items = my @lengths = sort {$b<=>$a} map {length($_)} keys %{$ref->{content}};
		# ...and grab the first number in the list to get the display width.
		my $max_len = $lengths[0];
		die "Your display is too narrow for these items.\n"
			if $max_len + 7 > $mw;
		
		# How many digits will we need for the index?
		my $count_width = $num_items =~ tr/0-9//;
		# '5' covers the formatting bits (separator, parens, three spaces)
		my $span_width = $max_len + $count_width + 5;
		# Max number of items that will fit in the display width *or*
		# the total number of items if it's less than that.
		my $items_per_line = int($mw/$span_width) < $num_items ?
			int($mw/$span_width) : $num_items;
		# Figure out total width for printing; '-1' adjusts for box corners
		my $width = $items_per_line * ($span_width) - 1;

		# Display the menu, get the answer, and validate it
		my($answer, %list);
		{
			my $count;
			$t->Tputs("cl", 1, *STDOUT);
			print "." . "-" x $width . ".\n";
			for my $item (keys %{$ref->{content}}){
				# Create a number-to-entry lookup table
				$list{++$count} = $item;
				# Print formatted box body
				printf "| %${count_width}s) %-${max_len}s ", $count, $item;
				print  "|\n" unless $count % $items_per_line;
			}
			# If we don't have enough items to fill the last line, pad with empty cells
			if ($count % $items_per_line){
				my $pad = "|" . " " x ($span_width - 1);
				print $pad x ($items_per_line - $count % $items_per_line);
				print "|\n";
			}
			print "'" . "-" x $width . "'\n";

			print "Item number (1-$count, 0 to restart, 'q' to quit)? ";
			chomp($answer = <STDIN>);
			exit if $answer =~ /^q/i;
			redo unless $answer =~ /^\d+$/ && $answer >= 0 && $answer <= $count;
		}
		my $retval;
		if ($answer == 0){
			$retval = _resetdata();
		}
		else {
			$retval->{label} = "$ref->{label} >> $list{$answer}";
			$retval->{content} = $ref->{content}->{$list{$answer}};
		}
		return $retval;
	}
}

########################################################################################

1;

__END__

=head1 NAME
 
Term::Menu::Hierarchical - Perl extension for creating hierarchical menus
 
=head1 SYNOPSIS
 
=begin text

	### Create an arbitrary-depth menu
	use Term::Menu::Hierarchical;
   
	my %data = (
		Breakfast => {
			'Milk + Cereal' => 'A good start!',
			'Eggs Benedict' => 'Classic hangover fix.',
			'French Toast'  => 'Nice and easy for beginners.'
		},
		Lunch   =>  {
			'Mushroomwiches'=> 'A new take on an old favorite.',
			'Sloppy Janes'  => 'Yummy and filling.',
			'Corn Dogs'     => 'Traditional American fare.'
		},
		Dinner  =>  {
			Meat        =>  {
				'Chicken Picadillo' =>  'Mmm-hmm!',
				'Beef Stroganoff'   =>  'Is good Russian food!',
				'Turkey Paella'     =>  'Home-made goodness.'
			},
			Vegetarian  => {
				'Asian Eggplant'    =>  'Tasty.',
				'Broccoli and Rice' =>  'Fun.',
				'Chickpea Curry'    =>  'Great Indian dish!',
				'Desserts'          =>  {
					'Almond Tofu'   =>  'Somewhat odd but good',
					'Milk Shake'    =>  'Comfort food!'
				}
			}
		}
	 );
	 
	 menu(\%data);
   
  
 The top-level menu for the above input looks like this:
  
 .--------------------------------------------.
 | 1) Breakfast | 2) Dinner    | 3) Lunch     |
 '--------------------------------------------'
 Item number (1-3, 0 to restart, 'q' to quit)? 
  
  
	### What about keeping the top-level menu in order?
 
	use Term::Menu::Hierarchical;
	use Tie::IxHash;
	
	tie(my %data, 'Tie::IxHash',  
		Breakfast => {
			'Milk + Cereal' => 'A good start!',
			'Eggs Benedict' => 'Classic hangover fix.',
			'French Toast'  => 'Nice and easy for beginners.'
		},
		[ ... ]
	);
	
	menu(\%data);
  

 Output:

 .--------------------------------------------.
 | 1) Breakfast | 2) Lunch     | 3) Dinner    |
 '--------------------------------------------'
 Item number (1-3, 0 to restart, 'q' to quit)? 
  
 
=end text

=head1 DESCRIPTION
 
This module only exports a single method, 'menu', which takes an arbitrary-depth hashref as an argument. The keys at
every level are used as menu entries; the values, whenever they're reached via the menu, are displayed in a pager.
Many text files (e.g., recipe lists, phone books, etc.) are easily parsed and the result structured as a hashref; this
module makes displaying this kind of content into a simple, self-contained process.
 
The module itself is pure Perl and has no system dependencies; however, terminal handling always involves a pact with
the Devil and arcane rituals involving chicken entrails and moon-lit aok groves. Users are explicitly warned to beware,
and bug reports are always welcome.
 
Features:
  
=begin text
  
 * No limit on hashref depth
 * Self-adjusts to terminal width and height
 * Keeps track of the "breadcrumb trail" (displayed in the pager)
 * Somewhat rough but serviceable pure-Perl pager
 * Extensively tested with several versions of Linux
  
=end text 
 
=head2 EXPORT
  
 menu
    Takes a single argument, a hashref of arbitrary depth. See the included test scripts for further usage examples.
  
=head1 SEE ALSO

Term::Cap, Term::ReadKey, perl

=head1 AUTHOR

Ben Okopnik, E<lt>ben@okopnik.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ben Okopnik

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
