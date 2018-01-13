#LEXiTRON Mac Dictionary

This project transforms the [LEXiTRON](http://lexitron.nectec.or.th/) dictionary into a format usable by Mac's Dictionary.app. A copy of the original LEXiTRON data is included, as well, since it is extremely difficult to obtain from the source website.

## Building

First, convert the lex files into UTF-8 XML documents:

    perl scripts/fixformat.pl lexitron-data/etlex > build/etlex.tis-620
    iconv -f tis620 -t utf8 build/etlex.tis-620 > build/etlex.utf-8

    perl scripts/fixformat.pl lexitron-data/telex > build/telex.tis-620
    iconv -f tis620 -t utf8 build/telex.tis-620 > build/telex.utf-8

Next, generate the source Mac dictionary XML file:

    ...

Then use the dictionary development kit to generate the final dictionary file:

    ...

Place the resulting file in your dictionary directory; in Dictionary.app, go to File -> Open Dictionaries Folder. The file should be in the same folder as CoreDataUbiquitySupport.

Finally, in Dictionary.app go to Dictionary -> Preferences and check the box next to "LEXiTRON English/Thai". The dictionary should now be available for use.
