#!/usr/local/perl -w
use strict;
use warnings;
use Data::Dumper;
use File::Find;
use Cwd;

#INFORMATION -------------------------------------------------------------------
# author: David Kwan
# version: 0.02

#CHANGELOG ---------------------------------------------------------------------
#0.02 - changed from game finder to also find other media types. Changed to use hash structure for found media rather than array.

#DESCRIPTION  ------------------------------------------------------------------
#Outputs a report of all files and folders that follow the '[Author] Title' structure.

#IMPORTANT ---------------------------------------------------------------------


#USAGE -------------------------------------------------------------------------

#KNOWN BUGS / LIMITATIONS ------------------------------------------------------
#the match in find_media only accounts for up to 3 authors. (ie: [author1][author2][author3] title)

#TODO --------------------------------------------------------------------------


#PROGRAM SETTINGS --------------------------------------------------------------
my %types = (
    "games"  => "html?|zip|rar|7z|jar|rag|swf|exe",
    "books" => "html?|zip|rar|7z|txt|epub|pdf|mobi|cbz|gdoc|docx?e",
    "images"  => "zip|rar|7z|cbz|pdf|jpe?g|gif|bmp|png|svg|tiff?",
    "all"  => "html?|zip|rar|7z|txt|epub|pdf|mobi|cbz|gdoc|docx?e|jar|rag|swf|exe|jpe?g|gif|bmp|png|svg|tiff?",
);

#PERL SETTINGS -----------------------------------------------------------------
# local $|=1; #If set to nonzero, forces a flush right away and after every write or print on the currently selected output channel. 
# use constant DS=>"\\";
# undef $/; #read filehandles in as a scalar not an array
# local $Data::Dumper::Useqq = 1; #make dumper output \n and other special characters

#PROGRAM START -----------------------------------------------------------------
my $start = time;
print "Begin $0...\n";

#FILE HANDLING -----------------------------------------------------------------

my $outfileN = 'find_all_media.report.txt';
my $logfileN = "find_all_media.log";

open (OUT, ">" . $outfileN) or die $!;
open (LOG, ">" . $logfileN) or die $!;

#Argument check and type establishment

my $help_message = <<'HELP';
must provide media type:
                        games, books, images, all
HELP
my $type = lc(shift @ARGV);
if (! $type) {
    error($help_message)
}
error($help_message) if $type !~ /^(games|books|images|all)$/i;

#MAIN ---------------------------------------------------------------------------
my $dir = getcwd();
print LOG "Current DIR  :: $dir\n";
my $count = 0;
my %authors;
my $authors = \%authors;

find({wanted => \&find_media}, $dir); 
print LOG Dumper($authors);

# output report
print OUT "List of all $type in $dir\n" . ("-" x 80) . "\n";
foreach my $a (sort alnum_compar_case_insensitive keys %authors){
    print OUT $a . "\n";
    # my @gamesNoExt = map { (my $s = $_) =~ s/\.[\w\d]+$//i; $s } @{$authors->{$a}}; #lexical variable usage from: http://www.perlmonks.org/?node_id=613280

    foreach my $g (sort alnum_compar_case_insensitive keys %{$authors->{$a}}){
        if ($g =~ /\.[\w\d]+$/){ #if the game has an extension, its a file and not a folder.
            print OUT "\t$g\n";
        } else { #if the game is a folder, maybe do something different here in the future for readability
            print OUT "\t$g\n";       
        }
    }
}

close OUT;
close LOG;
my $duration = time - $start;
print "...End $0 :: $duration seconds elapsed.\n";

#SUBS------------------------------------------------------------------------------
sub find_media {
	#WE ARE NOW TRAVERSING THROUGH EACH FILE AND DIRECTORY OF THE ENTIRE DIRECTORY
	#$_ in the current file
    my $short = $_; #the filename or foldername (not path)
	my $path = $File::Find::name; #full path of each file or folder
    my $fileExt = $types{$type};

	if ($short =~ /^(\[[^\/]+?\](?:\s*\[[^\/]+?\])?(?:\s*\[[^\/]+?\])?)\s*([^\/]+)/i){ #if the file or folder matches the usual convention.
        my $author = $1;
        my $game = $2;
        add_media($author, $game, $path);
    } elsif ($path =~ /\/(\[[^\/]+\])\/([^\/]+\.(?:$fileExt))/i) { #if the file or folder is a certain filetype AND it's parent folder is an AUTHOR ONLY.
        my $author = $1;
        my $game = $2;
        add_media($author, $game, $path);
	} else {
        print LOG "SKIP :: $path\n";
    }
	# print LOG $_ . "\n" if -d $_;
}

sub add_media {
    my $author = shift;
    my $game = shift;
    my $path = shift;
    (my $gameNoExt = $game) =~ s/\.[\w\d]+$//;
    print LOG "*ADD :: $path :: $author :: $gameNoExt\n";
    $authors->{$author}->{$gameNoExt}++;
    return 1;
}

sub error {
    my $errormsg = shift;
    my @errorlog = @_;
    print "ERROR $errormsg\n";
    print LOG "ERROR $errormsg :: @errorlog\n" and exit;
}

sub warning {
    my $errormsg = shift;
    my @errorlog = @_;
    print "WARNING $errormsg\n";
    print LOG "WARNING $errormsg :: @errorlog\n";
}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}
# Perl trim function to remove whitespace from the start and end of the string
sub trim {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}
# Left trim function to remove leading whitespace
sub ltrim {
    my $string = shift;
    $string =~ s/^\s+//;
    return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim {
    my $string = shift;
    $string =~ s/\s+$//;
    return $string;
}

sub alnum_compar_case_insensitive($$) { #NATURAL/SORDID SORTING ALGORITHM SOURCED FROM:  https://codereview.stackexchange.com/questions/32761/how-do-you-sordid-sort-alphanumeric-strings
    #USAGE :: @sorted = sort alnum_compar @documents;
    my ($a0, $b0) = (shift, shift);
    my $a = uc($a0);
    my $b = uc($b0);
    my $c;

    while (length($a) && length($b)) {
        my @a = $a =~ /^(\d+|\D+)(.*)$/;
        my @b = $b =~ /^(\d+|\D+)(.*)$/;

        if ($a[0] =~ /^\d/ && $b[0] =~ /^\d/) {
            $c = int($a[0]) - int($b[0]);
        } else {
            $c = $a[0] cmp $b[0];
        }
        return $c if ($c != 0);

        $a = $a[1];
        $b = $b[1];
    }
    return length($a0) - length($b0);
}
