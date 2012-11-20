#!/usr/bin/env perl

use strict;
use warnings;

#Assign Feed URL
my $feedURL = $ARGV[0];

if(!defined($feedURL))
{
	print "Please enter in RSS URL\n ";
	die;
}

#Wget the the xml to the download.xml
`wget $feedURL -T 10 --no-proxy -O download.xml`;
#open the downloaded file
open XML, "download.xml" or die $!;

my @itemHashes =();
# Create an array separated by </item> end tags from downloaded XML file handler.
my @xmlDoc = split /(<\/item>)/, join( "", <XML>);

#Putting relevant item data within a hash, which is then placed into an array.
for my $i(0..$#xmlDoc)
{ 
	my %tempHash;
	$_ =$xmlDoc[$i];
	if( $_ =~ /^\s*<item>/)
	{
		#Remove newlines and excessive whitespace.
		$_ =~ s/\n|(\s){2,}//g;
		#Extract the title
		if($_ =~ /<title>(.*)<\/title>/g)
		{						
			$tempHash{"title"}= remove_tags($1);			
		}
		#Get Description
		if($_ =~/<description>(.*)<\/description>/g)
		{
			$tempHash{"description"}= remove_tags(	$1);	
		}
		# Get date published
		if($_ =~ /<pubDate>(.*)<\/pubDate>/)
		{		
			$tempHash{"date_published"}=$1;		
		}
		#Get the Author
		if($_ =~ /<dc:creator>(.*)<\/dc:creator>/)
		{	
			$tempHash{"author"}= remove_tags($1);
		}		
		#placing the hash within an array.
		unshift(@itemHashes, \%tempHash);
	}
}
#printing out all our items

for my $i (0..$#itemHashes)
{ 
	if(defined($itemHashes[$i]{"title"}))
	{
		print pretty_format("Title: ".$itemHashes[$i]{"title"})."\n"."----------------------"."\n";
	}
	if($itemHashes[$i]{"description"})
	{
		print pretty_format("Description: ".$itemHashes[$i]{"description"})."\n"."----------------------"."\n";
	}
	if(defined($itemHashes[$i]{"date_published"}))
	{
		print "Date Published: ".$itemHashes[$i]{"date_published"}."\n"."----------------------"."\n";
	}else
	{
		print "Date: N\/A\n";
	}
	if(defined($itemHashes[$i]{"author"}))
	{
		print "Author: ".$itemHashes[$i]{"author"}."\n"."----------------------"."\n";
	}else
	{
		print "Author: N\/A\n";
	}	
	print "***************************\n";
}

=pretty_format
Prints out a string ensuring it is 80 characters wide, preserves integrity of words.
Takes a string as a parameter and returns a string which will fit within the 80 character requirement

=cut

sub pretty_format
{
	my $string = $_[0];
	my $j;
	for (my $i = 78; $i < length($string); $i += 78 )
	{	
		if((substr($string,$i,1))=~/\s/)
		{
			substr($string,$i,1,"\n");
		}
		else
		{		
			$j = $i-1;
			while (substr($string,$j,1) =~ /\S/)
			{				
				$j--;				
			}			
			substr($string,$j,1,"\n");
		}
	}
	return $string;
}

sub remove_tags
{
	my $string = $_[0];
	$string =~s/<!\[CDATA\[|<p>|<\/p>|\]\]>|<(.*?)>|&nbsp//g;
	return $string;
}