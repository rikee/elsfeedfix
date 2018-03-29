#!/usr/bin/perl

# elsfeedfix program used for downloading images from the els feed and generating an sql update script

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use XML::Simple;
use LWP::Simple;

my $help = 0;
my $filename = 0;
GetOptions ('help|?' => \$help,
			'filename=s' => \$filename);

my $feed_base_url = 'http://listings.equitylifestyle.com/';
my $images_dir = 'images';
my $sql_dir = 'sql';

if ($help) {
	print "--filename -> text file with all home IDs listed (1 per line, no commas)\n";
	print "perl elsedb.pl --filename homes.txt\n";
	exit 1;
}

if (!$filename) {
	print "You must enter a filename for the database.\n";
	print "perl elsdb.pl --filename example.sql --dbname eebeta_rvotg\n";
	exit 0;
}

# download the xml feed
print "Downloading ELS home feed ....\n";
my $data = get($feed_base_url . 'els-equitylifestyle.xml');
die "Couldn't download feed!" unless defined $data;

my $parser = new XML::Simple;
print "Parsing XML ....\n";
my $dom = $parser->XMLin($data, forcearray => 1);

#print Dumper($dom->{'listing'}->{'7960M008'}->{'gallery'}->[0]->{'url'}->[0]->{'content'});


# open the text file and add homes to array
print qq{Opening file $filename\n};
open(INPUT, "<$filename") || die "Couldn't open file $filename, $!";
my @input = <INPUT>;
close(INPUT);

print "List of home IDs read:\n";
my @home_ids;
foreach my $line (@input) {
	print qq{$line};
	$line =~ s/\s+\z//;
	push(@home_ids, $line);
}
print "\n";


# create images and sql directories if not exists
mkdir($images_dir) unless(-d $images_dir);
mkdir($sql_dir) unless(-d $sql_dir);


# create sql files
# mymh prefix
{
	print qq{Creating $sql_dir/mymh_images.sql (mymh prefix)\n};
	open my $fh, '>', $sql_dir . '/mymh_images.sql';
	foreach my $id (@home_ids) {
		print {$fh} "UPDATE `mymh`.`hw2sn_els_homes`\n";
		my $main_name = $dom->{'listing'}->{$id}->{'main_photo'}->[0]->{'content'};
		$main_name =~ s/$feed_base_url//;
		print {$fh} "SET main_photo = '" . $main_name . "',\n";
		print {$fh} "\tgallery = '[";
		my @gallery = @{$dom->{'listing'}->{$id}->{'gallery'}->[0]->{'url'}};
		my $count = 0;
		foreach my $img (@gallery) {
			my $image_name = $img->{'content'};
			$image_name =~ s/$feed_base_url//;
			if ($count > 0) {
				print {$fh} ",\"" . $image_name . "\"";
			}
			else {
				print {$fh} "\"" . $image_name . "\"";
			}
			$count++;
		}
		print {$fh} "]'\n";
		print {$fh} "WHERE listing = '" . $id . "';\n\n";
	}
	close $fh;
}
# qa prefix
{
	print qq{Creating $sql_dir/mymh_images_qa.sql (eebetaco_mymh prefix)\n};
	open my $fh, '>', $sql_dir . '/mymh_images_qa.sql';
	foreach my $id (@home_ids) {
		print {$fh} "UPDATE `eebetaco_mymh`.`hw2sn_els_homes`\n";
		my $main_name = $dom->{'listing'}->{$id}->{'main_photo'}->[0]->{'content'};
		$main_name =~ s/$feed_base_url//;
		print {$fh} "SET main_photo = '" . $main_name . "',\n";
		print {$fh} "\tgallery = '[";
		my @gallery = @{$dom->{'listing'}->{$id}->{'gallery'}->[0]->{'url'}};
		my $count = 0;
		foreach my $img (@gallery) {
			my $image_name = $img->{'content'};
			$image_name =~ s/$feed_base_url//;
			if ($count > 0) {
				print {$fh} ",\"" . $image_name . "\"";
			}
			else {
				print {$fh} "\"" . $image_name . "\"";
			}
			$count++;
		}
		print {$fh} "]'\n";
		print {$fh} "WHERE listing = '" . $id . "';\n\n";
	}
	close $fh;
}
# production prefix
{
	print qq{Creating $sql_dir/mymh_images_production.sql (eebetaco_elsjoomla prefix)\n};
	open my $fh, '>', $sql_dir . '/mymh_images_production.sql';
	foreach my $id (@home_ids) {
		print {$fh} "UPDATE `eebetaco_elsjoomla`.`hw2sn_els_homes`\n";
		my $main_name = $dom->{'listing'}->{$id}->{'main_photo'}->[0]->{'content'};
		$main_name =~ s/$feed_base_url//;
		print {$fh} "SET main_photo = '" . $main_name . "',\n";
		print {$fh} "\tgallery = '[";
		my @gallery = @{$dom->{'listing'}->{$id}->{'gallery'}->[0]->{'url'}};
		my $count = 0;
		foreach my $img (@gallery) {
			my $image_name = $img->{'content'};
			$image_name =~ s/$feed_base_url//;
			if ($count > 0) {
				print {$fh} ",\"" . $image_name . "\"";
			}
			else {
				print {$fh} "\"" . $image_name . "\"";
			}
			$count++;
		}
		print {$fh} "]'\n";
		print {$fh} "WHERE listing = '" . $id . "';\n\n";
	}
	close $fh;
}

# download images and create sql file
foreach my $id (@home_ids) {
	my @gallery = @{$dom->{'listing'}->{$id}->{'gallery'}->[0]->{'url'}};
	foreach my $img (@gallery) {
		print qq{Downloading photo: $img->{'content'}\n};
		my $image_name = $img->{'content'};
		$image_name =~ s/$feed_base_url//;
		my $response = getstore($img->{'content'}, $images_dir . '/' . $image_name );
		die "Couldn't download image!" unless $response == 200;
	}
}

exit 1;