#! /usr/bin/env perl
use strict;
use warnings; 


my @itemHashes =();
my $outputType;
my $htmlFlag=0;
my $textFlag=0;
my $xmlFlag =0;
my $cutoff=0;
my $cutoffFlag;
my $extension;

my %months=("Jan",1,
			"Feb",2,
			"Mar",3,
			"Apr",4,
			"May",5,
			"Jun",6,
			"Jul",7,
			"Aug",8,
			"Sep",9,
			"Oct",10,
			"Nov",11,
			"Dec",12);
#File handler opened using first command line argument
open (FEEDS, "$ARGV[0]") or die $!;

$outputType = $ARGV[1];

if(defined($ARGV[2]))
{
	$cutoff = $ARGV[2];
}

my @feeds = <FEEDS>;
#Printing the feeds

for(my $i = 0; $i<$#feeds+1; $i++)
{
	chomp $feeds[$i];
	#print "array index $i\n";
	#print $feeds[$i]."\n";
}

close FEEDS;

$outputType =~ /.*\.(.*)/;
$extension = $1;

if(!defined($extension))
{
	#kill the program on a bad file output
	print "Please enter a file with extension .txt, .html, .xml\n";
	die;
}

if($extension eq "html" || $extension eq "htm")
{
	$htmlFlag = 1;
}
elsif($extension eq "txt")
{
	$textFlag = 1;
}
elsif($extension eq "xml")
{
	$xmlFlag =1;
}
else
{
	print "Please enter a file with extension .txt, .html, .xml\n";
	die;
}

for(my $i = 0;$i<$#feeds+1; $i++)
{ 
	my $sampleURL = $feeds[$i];

	`wget $sampleURL -T 10 --no-proxy -q -O download.xml`;
	#Parser Processing of XML
	open XML, "download.xml" or die $!;

	# Create an array separated by </item> end tags from downloaded XML file handler.
	my @xmlDoc = split /(<\/item>)/, join( "", <XML>);

	#Putting relevant item data within a hash, which is then placed into an array.
	for my $j(0..$#xmlDoc)
	{ 
		my %tempHash;
		$_ =$xmlDoc[$j];
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
			
				$tempHash{"description"}= remove_tags($1);	
			}
			# Get date published
			if($_ =~ /<pubDate>(.*)<\/pubDate>/)
			{	
				$tempHash{"rawDate"}=$1;
				$tempHash{"date_published"}=parse_date($1);
			}else
			{
				print "NO DATE\n";
			}
			#Get the Author
			if($_ =~ /<dc:creator>(.*)<\/dc:creator>/)
			{	
				$tempHash{"author"}= remove_tags($1);
			}		
			#placing the hash within an array.
			
			#check whether the 3rd command has been entered, if so checks whether the article is on or after the date specified if yes, it enters it into the array. If the 3rd command line isnt set it just adds it in
			if($cutoff)
			{
				$cutoffFlag = date_compare($tempHash{"date_published"},$cutoff);
				
				if($cutoffFlag==1 || $cutoffFlag==0)
				{
					unshift(@itemHashes, \%tempHash);
				}
			}
			else
			{			
				unshift(@itemHashes, \%tempHash);
			}
		}
	}	
}
@itemHashes = sort_items(\@itemHashes);

output_to_file();

sub print_to_txt
{
	open OUTPUT ,">$outputType" or die;
	for my $j (0..$#itemHashes)
		{ 
			if(defined($itemHashes[$j]{"title"}))
			{
				print OUTPUT pretty_format("Title: ".$itemHashes[$j]{"title"})."\n"."----------------------"."\n";
			}
			if($itemHashes[$j]{"description"})
			{
				print OUTPUT pretty_format("Description: ".$itemHashes[$j]{"description"})."\n"."----------------------"."\n";
			}
			if(defined($itemHashes[$j]{"rawDate"}))
			{
				print OUTPUT "Date Published: ".$itemHashes[$j]{"rawDate"}."\n"."----------------------"."\n";
			}else
			{
				print  OUTPUT "Date: N\/A\n";
			}
			if(defined($itemHashes[$j]{"author"}))
			{
				print OUTPUT "Author: ".$itemHashes[$j]{"author"}."\n"."----------------------"."\n";
			}else
			{
				print OUTPUT "Author: N\/A\n";
			}	
			print OUTPUT "***************************\n";
		}	
		close OUTPUT;
}

=remove_tags
Function to remove tags from Title, Description and Author.
Some pages use HTML tags embedded into the into the content using CDATA, this removes them
=cut


sub remove_tags
{
# used to remove embedded html tags for text output, preserves tags for html output
	my $string = $_[0];
	
	if($htmlFlag==1)
	{
		$string =~s/(<!\[CDATA\[)|(\]\]>)//g;
	}
	else
	{ 
		$string =~s/<!\[CDATA\[|<p>|<\/p>|\]\]>|<(.*?)>|&nbsp//g;
	}
	
	return $string;
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
		#The boundary happens to be a space, add a newline
			substr($string,$i,1,"\n");
		}
		else
		{
		#Loop back to the next space
			$j = $i-1;
			while (substr($string,$j,1) =~ /\S/)
			{
				#keep backtracking
				$j--;				
			}
			#Space found, put a new line there.
			substr($string,$j,1,"\n");
		}
	}
	$string =~ s/^\s*//;
	return $string;
}
=parse_date
Returns a string with the Year, Month, Day, and time in format year-month-day-hours:minutes:seconds
=cut



sub parse_date
{
	my($year,$month,$date,$time);
	my $dateString = $_[0];
	#print "------------Raw date is $dateString\n";
	#grab, a single 1-2 digit string likely to be the date
	if($dateString =~/\b(\d{1,2})\b/g)
	{
		$date = $1;
	}
	
	if($dateString =~ /\b(\d{4})\b/g)
	{
		$year =$1;
	}	
	#grab the time 
	if(	$dateString =~ /(\d{2,}):(\d{2,}):(\d{2,})/g)
	{
		$time = "$1:$2:$3";
	}		
	
	for my $key (keys %months)
	{
		if($dateString =~ /($key.*)/g)
		{			
			$month = $months{$key};
		}			
	}
	
	#print "Date String is $year-$month-$date-$time\n";
	return "$year-$month-$date-$time" ;
}

sub sort_items
{
	my @unsortedList =@{$_[0]};	
	my $tempKey;
	my  %sortHash=();
	my @sortedList = ();
	#print $unsortedList[0]{"date_published"};
	
	for my $i (0..$#unsortedList)
	{
		$tempKey = $unsortedList[$i]{"date_published"};
	#	print "$tempKey \n";
		$sortHash{$tempKey} = $unsortedList[$i];
	}
	
	foreach my $key(sort keys %sortHash)
	{
		#print $sortHash{$key};
		push @sortedList, $sortHash{$key};
	}

if(0)
{	
	for my $i (0..$#sortedList)
	{
		print "DATE: ".$sortedList[$i]{"date_published"}."\n". "TITLE: ".$sortedList[$i]{"title"}."\n" ;
	}
}	
return @sortedList;
}

=output_to_file
Used to validate the output file extension. then chooses the appropriate output function.
=cut


sub output_to_file
{
	
	if(!defined($outputType))
	{
		print "output type undefined, Please enter filename with .txt, .html or .rss extension\n";
	}
	else
	{		
		 print "Output file is $extension\n"
	}
	print "extension is $extension\n";
	if($htmlFlag)	
	{	
		print "html flag is set\n";
		print_to_html();			
	}
	elsif($textFlag)	
	{
		print_to_txt();
	}
	elsif($xmlFlag)	
	{
		print_to_xml();
	}
}

sub print_to_html
{
	open OUTPUT ,">$outputType" or die;
	print OUTPUT
	"<html>
	<head>
    <title>Feed</title>
   </head>
   <body>";
   
   	for my $j (0..$#itemHashes)
		{ 
			if(defined($itemHashes[$j]{"title"}))
			{
				print OUTPUT "<h1>Title: ".$itemHashes[$j]{"title"}. "</h1>\n";
			}
			if($itemHashes[$j]{"description"})
			{
				print OUTPUT  $itemHashes[$j]{"description"};
				print OUTPUT "\n";
			}
			if(defined($itemHashes[$j]{"rawDate"}))
			{
				print OUTPUT "<p>"."Date Published: ".$itemHashes[$j]{"rawDate"}."</p>\n";
			}else
			{
				print OUTPUT "<p>"."Date: N\/A\n"."</p>\n";
			}
			if(defined($itemHashes[$j]{"author"}))
			{
				print OUTPUT  "<p>Author: ".$itemHashes[$j]{"author"}."</p>";
			}else
			{ 
				print OUTPUT  "<p>Author: N\/A </p>";
			}	
		print OUTPUT "\n";
		}	
   
   print OUTPUT "</body>
</html>";
	close OUTPUT;
	print "Printed to $outputType\n";
}

=print_to_xml
Prints output to XML file
=cut


sub print_to_xml
{	
	open OUTPUT ,">$outputType" or die;
	print OUTPUT '<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>My Feed</title>
  <description>My Special RSS feed</description>
    <link></link>';
	
		for my $j (0..$#itemHashes)
		{ 
			print OUTPUT "<item>\n" ;
			if(defined($itemHashes[$j]{"title"}))
			{
				print OUTPUT "<title>".$itemHashes[$j]{"title"}. "</title>\n";
			}
			if($itemHashes[$j]{"description"})
			{
				print OUTPUT  "<description>".$itemHashes[$j]{"description"}."</description>";
				print OUTPUT "\n";
			}
			if(defined($itemHashes[$j]{"rawDate"}))
			{
				print OUTPUT "<pubDate>".$itemHashes[$j]{"rawDate"}."</pubDate>\n";
			}else
			{
				print OUTPUT "<pubDate>"." N\/A\n"."</pubDate>\n";
			}
			if(defined($itemHashes[$j]{"author"}))
			{
				print OUTPUT  "<dc:creator>Author: ".$itemHashes[$j]{"author"}."</dc:creator>";
			}else
			{ 
				print OUTPUT  "<dc:creator>Author: N\/A </dc:creator>";
			}	
		print OUTPUT "\n";
		print OUTPUT '</item>' ;
		print OUTPUT "\n"
		}	
	
	print OUTPUT '</channel>
</rss>';
	close OUTPUT;
	print "Printed to $outputType\n";
}

=date_compare
returns 1 if first date is later than second 0 if the same, -1 if it is earlier
=cut



sub date_compare
{
	my ($dateString1,$dateString2, $year1,$month1,$date1,$year2,$month2,$date2);
	#dateString1 is the date of the article, dateString2 is the cutoff point
		
	
	$dateString1 = $_[0]; 
	$dateString2 = $_[1];
		
	$dateString1 =~ /(\d{4})\-(\d{1,2})-(\d{1,2})/;
	
	$year1 = $1;
	$month1 =$2;
	$date1 = $3;
	
	$dateString2 =~ /(\d{2})\/(\d{2})\/(\d{4})/;
	
		
	$date2 = $1;
	$month2 = $2;
	$year2 = $3;
	
		
	if($year1 > $year2)
	{
		return 1;
	}
	elsif($year1 < $year2)
	{
		return -1;
	}
	elsif($month1 > $month2)
	{
		return 1;
	}
	elsif($month1 < $month2)
	{
		return -1;
	}
	elsif($date1 > $date2)
	{
		return 1;
	}
	elsif($date1 < $date2)
	{
		return -1;
	}
	else
	{
		return 0;
	}
	
}



































