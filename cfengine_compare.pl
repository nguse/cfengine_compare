#!/usr/bin/env perl

# This perl script will search for cfengine replaced_files and compare
# them with the new files

# Note: The possible combinations of separators is not entirely known
# you may find you need to add more if it can't find matching files.

use strict;
use warnings;
use utf8;
use feature ':5.10';

# Using system diff instead of this library for portability
# use Text::diff;

# Place to look for replaced files
my $path = '/var/cfengine/replaced_files/';

# Seperators cfengine might replace with in the filename for an underscore
my @separators = ('/', '.', '_', '-');

# Verbose output
my $verbose = 0;

sub find_file {
	my ($starting_path, $search, $indent) = @_;

	say "    " x $indent . "Starting path: $starting_path" if $verbose;
	say "    " x $indent . "Search: $search" if $verbose;

	if (index($search, '_') == -1) {
		# nothing left we could replace
		if (-e $starting_path . $search) {
			return $starting_path . $search;
		}

		return 0;
	}

	my ($segment, $new_search) = split(/_/, $search, 2);

	$indent++;

	# First, test each file in this path
	foreach my $separator (@separators) {
		my $new_starting_path = $starting_path . $segment . $separator;

		say "    " x $indent . "Test: $new_starting_path$new_search" if $verbose;

		if (-e $new_starting_path . $new_search) {
			return $new_starting_path . $new_search;
		}
	}

	say '' if $verbose;

	# Then recurse
	foreach my $separator (@separators) {
		my $new_starting_path = $starting_path . $segment . $separator;

		my $match = find_file($new_starting_path, $new_search, $indent);

		if ($match) {
			return $match;
		}
	}
}

# Function is used for testing
# Input a real path, such as:
# /etc/hosts
# and get back a string can pass to find_file as $search:
# etc_hosts
sub replace_to_test {
	my ($string) = @_;
	$string =~ s/\///;
	$string =~ s/[\/\.\-]/_/g;

	return $string;
}

# ----- Testing -----
# foreach my $test (
# 	# '/etc/hosts',
# 	# '/etc/security/audit_event',
# 	'/test/test/test_test_test/.test'
# ) {
# 	# say replace_to_test($test);
# 	say ':' . find_file('/', replace_to_test($test), 0);
# }
# exit;

opendir(my $dh, $path) || die "Cant open $path: $!";

while (my $file = readdir $dh) {
	# ignore files not ending with _cfsaved
	if (index($file, '_cfsaved') == -1) {
		next;
	}

	my $search = $file;

	# remove trailing _cfsaved
	$search =~ s/_cfsaved$//;

	# remove leading underscore
	$search =~ s/^_//;

	say '-------------------------------';
	say $search;

	my $match = find_file('/', $search, 0);

	if ($match) {
		say "Found Match at $match";

		# Using system diff instead of Text:Diff library for portability
		system("diff $match $path/$file");
		# say diff($match, $_);

	} else {
		say "No match found!"
	}
}

closedir $dh;
