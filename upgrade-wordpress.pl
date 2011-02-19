#!/usr/bin/perl

=pod

=head1 ID

=over

=item $Author: imran $

=item $Date: 2010-10-08 08:54:48 $

=item $RCSfile: upgrade-wordpress.pl,v $

=item $Revision: 1.12 $

=back

=head1 NAME

upgrade-wordpress.pl

=head1 SYNOPSIS

Upgrade Wordpress to the latest version.

Usage summary: ./upgrade-wordpress.pl

=head1 DESCRIPTION

How to use:

=over

=item 1. Log-in as privileged user.

=item 2. Ensure there is no file named 'latest.tar.gz' in the current dir.

=item 3. Run this script with dry-run mode first (-n)

=item 4. Assuming all ok, run in live mode (-r)

=item 5. Log-in to Admin CP and do the database upgrade if prompted.

=item 6. Check site is OK.

=back

=head1 TODO

=over

=item * warn if downgrading

=item * warn if versions are the same

=item * yes/no - prompt to deleting tarball if found

=item * use GetOpts

=item * option to skip downloading the file

=item * option to skip decompression

=item * have an "everything OK so far?" just before the rsync in --run mode -
with y/N

=item * option to be verbose in --run mode

=back

=cut

use strict;

my $o_standard = '-rlpth';
my $o_dry_run = '--dry-run';
my $o_verbose = '';
my $tarball = 'latest.tar.gz';

if(scalar @ARGV > 1)
{ 
	print "error: too many arguments.\n";
	usage(); 
}

if($ARGV[0] eq '-r' or $ARGV[0] eq '--run')
{
	$o_dry_run = '';
}
elsif($ARGV[0] eq '-n' or $ARGV[0] eq '--dry-run')
{
	$o_dry_run = '--dry-run';
	$o_verbose = '--verbose';
}
elsif($ARGV[0] eq '-h' or $ARGV[0] eq '--help')
{
	usage(); 
}
else
{
	usage();
}

## Test if latest.tar.gz exists and complain if so
if (-e $tarball)
{
	print "Warning! Found [$tarball] in working directory Please delete this and run again.\n";
	exit;
} 

print "Downloading the latest version of Wordpress... \n";
`wget http://wordpress.org/$tarball`;
print "[DONE]\n\n";
print "Decompressing archive... ";
`tar -xzvf $tarball`;
print "[DONE]\n\n";

print "Current version... \t";
print "[", wp_version('/usr/share/wordpress/wp-includes/version.php'), "]\n";
print "New version... \t\t";
my $new_version = wp_version('wordpress/wp-includes/version.php');
print "[$new_version]\n\n";

print "Upgrading Wordpress... ";
## rsync will give excludes priority over includes - which is why when 
## the wp-content dir is in the exclude list, the dirs wp-content/cache and 
## wp-content/plugins/widgets in the include list are not looked at.
##
## Exclude certain files and dirs.
my @output = `rsync $o_dry_run $o_verbose $o_standard ./wordpress /usr/share/ --exclude-from=lib/wordpress-excludes.txt`;
print @output;

## IC - both the below source dirs did not appear to be present so ignore for now.

## Include [./wordpress/wp-content/cache]
#@output = `rsync $o_dry_run $o_verbose $o_standard ./wordpress/wp-content/cache /usr/share/wordpress/wp-content`;
#print @output;

## Include [./wordpress/wp-content/plugins/widgets]
#@output = `rsync $o_dry_run $o_verbose $o_standard ./wordpress/wp-content/plugins/widgets /usr/share/wordpress/wp-content/plugins`;
#print @output;

print "\n[DONE]\n\n";

if($ARGV[0] eq '-r' or $ARGV[0] eq '--run')
{
	print "Now that you have upgraded for real, log-in to Admin CP and do the database upgrade if prompted.\n\n";
}

sub usage
{
	print "Usage: $0 [OPTION]\n\n";
	print "Options\n";
	print " -r, --run\t\tdo upgrade.\n";
	print " -n, --dry-run\t\tdo not upgrade, just show files to be copied.\n";
	print " -h, --help\t\tshow this help.\n";
	exit;
}

sub wp_version
{
	my ($path) = @_;
	my $version;

	open(VERSION, "$path") or die "Could not open version file: $!\n";

	while(<VERSION>)
	{
		/wp_version\s*=\s*'(.*)';/;
	
		if(defined $1)
		{
			$version = $1;
			last;
		}
	}

	close(VERSION);
	return $version;
}

=head1 AUTHOR

Imran Chaudhry, <ichaudhry@gmail.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
