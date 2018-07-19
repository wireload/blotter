#!/usr/bin/env python

import cli.log
import sh
from path import path

LANGUAGES = {
    "de": {'lproj': ("German.lproj",) , 'glossary': "German"},
    "en": {'lproj': ("English.lproj", ) , 'glossary': "English"},
    "es": {'lproj': ("Spanish.lproj", ), 'glossary': "Spanish"},
    "fr": {'lproj': ("French.lproj", ), 'glossary': "FU"},
    "ko": {'lproj': ("ko.lproj", ), 'glossary': "Korean"},
    "ru": {'lproj': ("ru.lproj", ), 'glossary': "Russian"},
    "sv": {'lproj': ("sv.lproj", ), 'glossary': "Swedish"},
    "ja": {'lproj': ("Japanese.lproj", ), 'glossary': "Japanese"},
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

    app.log.info("Searching glossary strings...")
    print sh.grep("-i", "-4", app.params.pattern, sh.glob(glossary_folder / "*.lg"), _out=process_output, _err=process_error)

    resource_folders = set(LANGUAGES[app.params.language]['lproj'])
    resource_folders.add("{}.lproj".format(app.params.language))

    for root in ("/Applications/", "/System/"):
        app.log.info("Searching {} strings...".format(root))
        for resource_folder in resource_folders:
            for name in sh.find(root, '-ipath', "*%s*" % resource_folder, "-iname", "*.strings", "-print", _err=process_error, _ok_code=[0, 1]):
                name = name.strip()
                try:
                    with open(name, "rb") as f:
                        c = f.read()
                    if not app.params.pattern in c:
                        continue
                        
                    r = [l for l in sh.plutil("-convert", "json", "-r", "-o", "-", name, _err=process_error) if app.params.pattern in l]
                
                    if r:
                        app.log.info(name)
                        app.log.info("\n".join(r))
                except Exception as e:
                    app.log.error("Failed to check %s (%s).", name, e)
                

greptrans.add_param("language", help="target language code", choices=LANGUAGES.keys())
greptrans.add_param("pattern", help="base language (English) text to search for", type=str)


if __name__ == "__main__":
    greptrans.run()
