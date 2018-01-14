# LEXiTRON Mac Dictionary

This project transforms the [LEXiTRON](http://lexitron.nectec.or.th/) dictionary into a format usable by Mac's Dictionary.app. A copy of the original LEXiTRON data is included, as well, since it is extremely difficult to obtain from the source website.

## Building

First, LEXiTRON contains lots of illegal character combinations (probably typos). These will trip-up the dictionary compiler later, so they should be fixed using [thaicheck](http://www.lyndonhill.com/Projects/thaicheck.html). Note that these commands will print lots and lots of errors; these are just logging statements indicating the problems that are being fixed.

    thaicheck -r lexitron-data/telex -f > build/telex.fixed
    thaicheck -r lexitron-data/etlex -f > build/etlex.fixed

Next, convert the files to proper UTF-8-encoded XML. Note that there are several encoding problems in etlex; you can ignore the `iso-8859-11 "\xFC" does not map to Unicode` warnings.

    perl scripts/fixformat.pl build/etlex.fixed > build/etlex.utf-8
    perl scripts/fixformat.pl build/telex.fixed > build/telex.utf-8

Next, generate the source Mac dictionary XML file:

    perl scripts/convert_to_mac.pl en-th build/etlex.utf-8 >build/LEXiTRON_en-th.xml
    perl scripts/convert_to_mac.pl th-en build/telex.utf-8 >build/LEXiTRON_th-en.xml

Then use the dictionary development kit to generate the final dictionary file. First, edit resources/Makefile so that the `DICT_BUILD_TOOL_DIR` points to your [Dictionary Development Kit](https://github.com/SebastianSzturo/Dictionary-Development-Kit.git) location. Then execute the following:

    cd resources
    export DICT_BUILD_TOOL_DIR='path/to/your/[Dictionary/Development/Kit](https://github.com/SebastianSzturo/Dictionary-Development-Kit.git)'
    make -f makefile_en-th all install
    make -f makefile_th-en all install

Place the resulting file in your dictionary directory; in Dictionary.app, go to File -> Open Dictionaries Folder. The file should be in the same folder as CoreDataUbiquitySupport.

Finally, in Dictionary.app go to Dictionary -> Preferences and check the box next to "LEXiTRON English/Thai". The dictionary should now be available for use.

## TODO

* Doesn't show in Dictionary.app sometimes but still works from CLI ???
* Better CSS
* Should also generate a single En-TH/TH-EN dictionary.
* One-step build
* Include Dictionary-Toolkit as subrepo
* add license

