use strict;
use warnings;
use FindBin '$Bin';

my $en_th_path = "$Bin/../build/LEXiTRON_en-th.xml";
my $th_en_path = "$Bin/../build/LEXiTRON_th-en.xml";
my $out_file = "$Bin/../build/LEXiTRON_combined.xml";

open my $out_fh, ">:encoding(UTF-8)", $out_file;

open my $en_th_fh, "<:encoding(UTF-8)", $en_th_path;
open my $th_en_fh, "<:encoding(UTF-8)", $th_en_path;
<$en_th_fh>;
<$en_th_fh>;
<$th_en_fh>;
<$th_en_fh>;
print $out_fh <<END;
<?xml version="1.0" encoding="UTF-8"?>
<d:dictionary xmlns="http://www.w3.org/1999/xhtml" xmlns:d="http://www.apple.com/DTDs/DictionaryService-1.0.rng">"
END

while(my $line = <$en_th_fh>) {
    last if($line eq "</d:dictionary>\n");
    print $out_fh $line;
}
while(my $line = <$th_en_fh>) {
    print $out_fh $line;
}
