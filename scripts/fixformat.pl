#!/usr/env perl
# Convert LEXiTRON from improperly-formatted XML in TIS-620 to proper XML in UTF-8
# There will be several warnings printed when processing etlex; apparently it has some encoding problems. I believe these can be safely ignored.

binmode STDOUT, ':utf8';

if (@ARGV != 1) {
    die "Usage: perl fixformat.pl <telex|etlex>";
}

open my $fh, '<:encoding(iso-8859-11)', $ARGV[0]
    or die "Couldn't open file $ARGV[0]";

print qq(<?xml version="1.0" encoding="UTF-8"?>\n);
print "<dic>\n";
while (<$fh>) {
    # escape ampersand
    s/&/&amp;/sg;
    # escape less than
    s/.*>.*\K<(?=.*<)/&lt;/sg;
    # Fix problems with Thai chars in telex
    s/>์/>/g;
    print;
}
print "</dic>\n";
