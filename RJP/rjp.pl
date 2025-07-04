#!/usr/bin/env perl

use strict;
use warnings;

# BBEdit filters read from stdin and write to stdout
# Variables to track YAML frontmatter
my $in_frontmatter = 0;
my $frontmatter_found = 0;
my $line_num = 0;

# Process input line by line
while (my $line = <STDIN>) {
    $line_num++;
    
    # Check for YAML frontmatter start
    if ($line_num == 1 && $line =~ /^---\s*$/) {
        $in_frontmatter = 1;
        $frontmatter_found = 1;
        next;
    }
    
    # Check for YAML frontmatter end
    if ($in_frontmatter && $line =~ /^---\s*$/) {
        $in_frontmatter = 0;
        next;
    }
    
    # Skip lines within frontmatter
    next if $in_frontmatter;
    
    # Output regular content to stdout
    print $line;
}
