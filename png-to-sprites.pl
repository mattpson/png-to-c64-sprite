#!/usr/bin/env perl

use strict;
use warnings;

# enable perl 5.10 features
use v5.10;

# use these modules
use Carp;
use Data::Dumper;
use Getopt::Long;
use Image::PNG;

# define which version thi sis
our $VERSION = 1.0;

# define variables
my $binary = '';
my $hex = '';
my $filename;
my $pad = '';
my $verbose = '';

# set up command line options
GetOptions (
"binary" => \$binary,
"hex" => \$hex,
"pad" => \$pad,
"verbose" => \$verbose,
"version" => sub { say "version $VERSION"; exit; }
);

# sanity check some options
if ($hex && $binary) { croak "Options binary and hex is exclusive - pick one"; }

# set binary as default if none are set
unless ($hex && $binary) { $binary = 1; }

# make sure the other option is zeroed out
if ($hex) { $binary = 0; }
if ($binary) { $hex = 0; }

# filename should be in @ARGV (we only support a single one)
$filename = pop @ARGV;
say "Input filename: " . $filename if $verbose;

# do some basic file checks
unless (-e $filename) { croak "File error: $!"; }
unless (-r $filename) { croak "File not readable: $filename"; }
unless (-s $filename) { croak "File is zero bytes: $filename"; }

# set up the png object
my $png = Image::PNG->new ( {verbosity => 0} );

# read the file, will fail if the file is not a PNG image
$png->read ($filename);

# PNG file is loaded, if verbose print some information about it 
if($verbose) {
	# print PNG properties 
	say " Width: " . $png->width ();
	say " Height: " . $png->height ();
	say " Bit-depth: " . $png->bit_depth ();
}

# C64 sprites
# ===========

# high-res sprites always fits in to a "grid" of 24 bits in width, and 21 bits in height; a total of 504 bits, 
# which in turn fit into 63 bytes.

# one unused byte in each avaliable 64-byte "block"; the contents of this "64th byte" has no influence on 
# the sprite's appearance.

# ----------
# | 0| 1| 2|
# ----------
# | 3| 4| 5|
# ----------
# ...
# ----------
# |61|62|63|
# ----------

# 63 bytes = 1 sprite

# check if we have data in the png for one single colour sprite
if ( ($png->width()==24) && ($png->height()==21) && ($png->bit_depth()==1)) {
	# we have a single single-colour sprite

	my @i = (0 .. 20); #21 lines

	my $rows = $png->rows ();

	foreach my $line (@i) {

		my $bytes =  shift @{ $rows }; # take the first value of the array
		my @btmp = unpack('C*',$bytes);
		my $i=0;

		print "\t" . '.byte ';

		foreach (@btmp) {
			my $spriteline;
			if($binary) {
				# binary
				$spriteline = sprintf "%0*b", 8, $_;
				print '%'.$spriteline;
			}

			elsif($hex) {
				# hex
				$spriteline = sprintf "%02X", $_;
				print '$'.$spriteline;
			}

			print ',' unless ($i==2);
			$i++;
		}
		print "\n";
	}

	# shall we pad to 64 bytes? (this is handy)

	if($pad) {
		if ($hex) { print "\t" . '.byte $00' . "\n"; }
		elsif ($binary) { print "\t" . '.byte %00000000' . "\n"; }
	}
}
else {
	say "Sorry, this version currently only supports a single single-colour sprite (so far).";
}
exit;
