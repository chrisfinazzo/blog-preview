#!/usr/bin/perl -n

BEGIN {
    $i = 0;
    $in_frontmatter = 0;
    open(HTML_PIPE, "| cmark");
}

if ($in_frontmatter) {
    if (/^---/) {
        $in_frontmatter = 0;
    }
} elsif (/^---/ && $i < 2) {
    $i++;
    $in_frontmatter = 1;
} else {
    print HTML_PIPE $_;
}

END {
    close(HTML_PIPE);
}
