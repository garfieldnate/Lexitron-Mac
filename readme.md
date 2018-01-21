# LEXiTRON Mac Dictionary

This project transforms the [LEXiTRON](http://lexitron.nectec.or.th/) dictionary into a format usable by Mac's Dictionary.app. A copy of the original LEXiTRON data is included here, as well, since it is extremely difficult to obtain from NECTEC due to technical problems with their website.

## Installing

You don't have to build the dictionaries yourself if you just want to install it and try it out. Just download the dictionary you want from the [releases section on GitHub](https://github.com/garfieldnate/Lexitron-Mac/releases), and place it in your home folder in `Library/Dictionaries`. Then, in Dictionary.app go to Dictionary -> Preferences and check the box next to the name of the dictionary (e.g. LEXiTRON something). The dictionary should now be available for use.

## Building

Required software:

* Mac OSX
* Perl (default one should be okay)
* [thaicheck](http://www.lyndonhill.com/Projects/thaicheck.html)
* [Dictionary Development Kit](https://github.com/SebastianSzturo/Dictionary-Development-Kit.git)

First, LEXiTRON contains lots of illegal character combinations (probably typos). These will trip-up the dictionary compiler later, so they should be fixed using thaicheck. Note that these commands will print lots and lots of "errors"; these are just logging statements indicating the problems that are being fixed.

    thaicheck -r lexitron-data/telex -f > build/telex.fixed
    thaicheck -r lexitron-data/etlex -f > build/etlex.fixed

Next, convert the files to proper UTF-8-encoded XML. Note that there are several encoding problems in etlex; you can ignore the `iso-8859-11 "\xFC" does not map to Unicode` warnings.

    perl scripts/fixformat.pl build/etlex.fixed > build/etlex.utf-8
    perl scripts/fixformat.pl build/telex.fixed > build/telex.utf-8

Next, generate the source Mac dictionary XML files:

    perl scripts/convert_to_mac.pl en-th build/etlex.utf-8 >build/LEXiTRON_en-th.xml
    perl scripts/convert_to_mac.pl th-en build/telex.utf-8 >build/LEXiTRON_th-en.xml

Then use the dictionary development kit to generate the final dictionary file. First, set the `DICT_BUILD_TOOL_DIR` environment variable to the location of your copy of the Dictionary Development Kit. Then execute `make` to compile the final dictionaries:

    export DICT_BUILD_TOOL_DIR='path/to/your/[Dictionary/Development/Kit](https://github.com/SebastianSzturo/Dictionary-Development-Kit.git)'
    cd resources
    make -f makefile_en-th all install
    make -f makefile_th-en all install

Finally, in Dictionary.app go to Dictionary -> Preferences and check the box next to "LEXiTRON English/Thai". The dictionary should now be available for use.

If you would like the combined EN-TH/TH-EN dictionary, then do the following (after generating the source Mac XML dictionary files above):

    perl scripts/combine.pl
    export DICT_BUILD_TOOL_DIR='path/to/your/[Dictionary/Development/Kit](https://github.com/SebastianSzturo/Dictionary-Development-Kit.git)'
    cd resources
    make -f Makefile_combined all install

## License

The `lexitron-data` folder is copyrighted by NECTEC and contains its own license files. The rest of the project is released under the MIT license (see `LICENSE`).

## TODO
* add CSS
* script to make all dictionaries and zip up them for release
* I don't understand LEXiTRON sequence numbers; fly1 occurs several times in etlex
* sometimes doesn't show in Dictionary.app but still works from CLI ???
* One-step build
* Include Dictionary-Toolkit as sub-repo
