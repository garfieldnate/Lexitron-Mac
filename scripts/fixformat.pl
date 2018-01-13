#!/usr/env perl
# Adapted from script retrieved from https://web.archive.org/web/20060226052127/http://linux.thai.net/plone/Members/poonlap/dictd/lexitron
# by Poonlap Veerathanabutr <poonlap at linux dot thai dot net>
# Jun 2004
# LEXiTRON is supposed to be encoded in tis620, but contains some bad characters. Fix those, and
# also add a root XML element so that it is a legal XML document.

print "<dic>\n";
while (<>) {
    @chars = split(//);
    foreach $c (@chars) {
        $dec = ord($c);
        if ( $dec == 133 ) {
            print "...";
        }
        elsif ( $dec == 145 || $dec == 146 ) {
            print "'";
            print stderr "'";
        }
        elsif ( $dec == 147 || $dec == 148 ) {
            print "\"";
            print stderr "\"";
        }
        elsif ( $dec == 149 ) {
            print "-";
            print stderr "-";
        }
        elsif ( $dec == 150 ) {
            print "--";
            print stderr "--";
        }
        elsif ( $dec == 151 ) {
            print "---";
            print stderr "---";
        }
        elsif ( $dec == 252 ) {
            print stderr "<FC>";
        }
        elsif ( $dec == 160 ) {
            print stderr "<A0>";
        }
        else {
            print $c;
        }
    }
}
print "</dic>\n";
