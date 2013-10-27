#!/usr/bin/env python

import cli.log
import sh
from path import path

LANGUAGES = {
    "de": {'lproj': "German.lproj", 'glossary': "DE-German-de"},
    "en": {'lproj': "English.lproj", 'glossary': "DE-German-de"},
    "es": {'lproj': "Spanish.lproj", 'glossary': "E-Spanish-es"},
    "fr": {'lproj': "French.lproj", 'glossary': "DE-German-de"},
    "ko": {'lproj': "ko.lproj", 'glossary': "DE-German-de"},
    "ru": {'lproj': "ru.lproj", 'glossary': "DE-German-de"},
    "sv": {'lproj': "sv.lproj", 'glossary': "DE-German-de"},
    "ja": {'lproj': "Japanese.lproj", 'glossary': "J-Japanese-ja"},
}


@cli.log.LoggingApp
def greptrans(app):
    def process_output(line):
        print line,

    def process_error(line):
        if "Permission denied" in line:
            return
        app.log.error(line[:-1])

    glossary_folder = path("/Volumes/{}".format(LANGUAGES[app.params.language]['glossary']))
    if not path.exists:
        raise Exception("Glossary volume {} not mounted".format(glossary_folder))

    app.log.debug("Searching glossary strings...")
    print sh.grep("-i", "-4", app.params.pattern, sh.glob(glossary_folder / "*.lg"), _out=process_output, _err=process_error)

    resource_folder = LANGUAGES[app.params.language]['lproj']

    for root in ("/Applications/", "/System/"):
        app.log.debug("Searching {} strings...".format(root))
        print sh.grep(sh.find(root, '-ipath', "*%s*" % resource_folder, "-iname", "*.strings", "-exec", "plutil", "-convert", "json", "-r", "-o", "-", "{}", ";", _err=process_error), app.params.pattern, _out=process_output, _err=process_error)

greptrans.add_param("language", help="target language code", choices=LANGUAGES.keys())
greptrans.add_param("pattern", help="base language (English) text to search for", type=str)


if __name__ == "__main__":
    greptrans.run()
