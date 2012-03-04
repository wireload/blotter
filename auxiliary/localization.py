#! /usr/bin/env python

from os.path import join, abspath, dirname, basename, splitext, isfile
from os import listdir
from tempfile import mkdtemp
from subprocess import check_call
from shutil import copy, rmtree
from re import findall
import argparse
from codecs import open

BLOTTER_DIR = join(dirname(abspath(__file__)), "..", "Blotter")
BLOTTER_PREFS_DIR = join(BLOTTER_DIR, "../", "Blotter Preferences")


def Strings(name, output_path):
    """
    Returns path to a strings file for given filename and output path.
    """
    return join(output_path, splitext(basename(name))[0] + ".strings")


def Lproj(lang, output_path):
    """
    Returns path to a dir for localized files for given lang and output path.
    """
    return join(output_path, lang + ".lproj")


def Xibs():
    """
    Returns a list of dicts of the following format:
    {'output' : output_path, 'file' : xib_path, 'old' : old_xib_path}
    Where output is the path to a root dir for all localizations,
    file is the path to a xib,
    old is the path to the previous version of the xib.
    """

    prefsResources = join(BLOTTER_PREFS_DIR, "Resources")
    xibs = [{'output': join(BLOTTER_DIR, "Resources"),
             'file': join(BLOTTER_DIR, "Resources", "English.lproj", "MainMenu.xib"),
             'old': join(BLOTTER_DIR, "Resources", "English.lproj", "MainMenu.old.xib")},
            {'output': join(BLOTTER_DIR, "Resources"),
             'file': join(BLOTTER_DIR, "Resources", "English.lproj", "NewEventWindow.xib"),
             'old': join(BLOTTER_DIR, "Resources", "English.lproj", "NewEventWindow.old.xib")},
            {'output': join(BLOTTER_DIR, "Resources"),
             'file': join(BLOTTER_DIR, "Resources", "English.lproj", "NewTaskWindow.xib"),
             'old': join(BLOTTER_DIR, "Resources", "English.lproj", "NewTaskWindow.old.xib")},
            {'output': prefsResources,
             'file': join(prefsResources, "English.lproj", "CalendarsPrefPaneView.xib"),
             'old': join(prefsResources, "English.lproj", "CalendarsPrefPaneView.old.xib")},
            {'output': prefsResources,
             'file': join(prefsResources, "English.lproj", "GeneralPrefPaneView.xib"),
             'old': join(prefsResources, "English.lproj", "GeneralPrefPaneView.old.xib")},
            {'output': prefsResources,
             'file': join(prefsResources, "English.lproj", "PositionPrefPaneView.xib"),
             'old': join(prefsResources, "English.lproj", "PositionPrefPaneView.old.xib")},
            {'output': prefsResources,
             'file': join(prefsResources, "English.lproj", "LayoutPrefPaneView.xib"),
             'old': join(prefsResources, "English.lproj", "LayoutPrefPaneView.old.xib")},
            ]
    return xibs


def Sources():
    """
    Returns a list of dicts of the following format:
    {'output' : output_path, 'files' : sources_paths}
    output is the path to a root dir for all localizations,
    files is a list of paths to sources
    """
    sources = [{'output': join(BLOTTER_DIR, "Resources"),
                'files': [join(BLOTTER_DIR, "WLCalendarWindowController.m"),
                          join(BLOTTER_DIR, "WLNewEventWindowController.m"),
                          join(BLOTTER_DIR, "WLNewTaskWindowController.m"),
                          join(BLOTTER_DIR, "WLCalendarTasksView.m")]},
               {'output': join(BLOTTER_PREFS_DIR, "Resources"),
                'files': [join(BLOTTER_PREFS_DIR, "GeneralPrefController.m"),
                          join(BLOTTER_PREFS_DIR, "PositionPrefController.m"),
                          join(BLOTTER_PREFS_DIR, "LayoutPrefController.m"),
                          join(BLOTTER_PREFS_DIR, "CalendarsPrefController.m"),
                          join(BLOTTER_PREFS_DIR, "NSScreen+WLScreenName.m"),
                          join(BLOTTER_PREFS_DIR, "WLScreensController.m")]}]
    return sources


def Langs():
    """
    Returns list of supported languages excluding development language.
    """
    return ["de", "es", "fr", "ko", "sv", "ru"]


def DevLang():
    """
    Returns development language.
    """
    return "English"


def MergeStrings(src_path, dst_path):
    """
    Merges to strings file in the following manner:
    if string exist in the src_path file and doesn't exist in the dst_path file, it will be added
    if string exist both in the src_path file and in the dst_path file, only its comment will be updated
    if string doesn't exist in the src_path file but exist in the dst_path file, it will be removed
    """

    def Parse(file):
        l = filter(lambda x: len(x.strip()), file.readlines())
        parsed = []
        for i in range(0, len(l), 2):
            comment = l[i].strip()
            key, value = findall("\"(?:[^\"\\\\]|\\\\.)*\"", l[i + 1])
            parsed.append({'key': key, 'value': value, 'comment': comment})
        return sorted(parsed, key=lambda x: x['key'])

    def Write(src_list, dst_file):
        for item in src_list:
            dst_file.write("\n".join([item['comment'], item['key'] + " = " + item['value'] + ";", "\n"]))

    src = open(src_path, 'r', 'utf-16')
    dst = None
    if isfile(dst_path):
        dst = open(dst_path, 'r+', 'utf-16')
    else:
        dst = open(dst_path, 'w+', 'utf-16')

    try:
        src_list = Parse(src)
        dst_list = Parse(dst)
        result = []
        i = 0
        j = 0
        while i < len(src_list) and j < len(dst_list):
            if src_list[i]['key'] < dst_list[j]['key']:
                # new string is added
                result.append(src_list[i])
                i += 1
            elif src_list[i]['key'] == dst_list[j]['key']:
                # update comment
                dst_list[j]['comment'] = src_list[i]['comment']
                result.append(dst_list[j])
                i += 1
                j += 1
            else:
                # string is removed
                j += 1
        if i < len(src_list):
            result += src_list[i:]
        dst.close()
        dst = open(dst_path, 'w', 'utf-16')
        Write(result, dst)
    finally:
        src.close()
        dst.close()


def LocalizeXib(xib_path, old_xib_path, output_path, langs):
    """
    Localizes xib for given langs using "--localize-incremental" flag.
    """
    print "Localize " + basename(xib_path)

    name = basename(xib_path)
    old_name = basename(old_xib_path)

    if not isfile(old_xib_path):
        copy(xib_path, old_xib_path)

    for lang in langs:
        print lang
        l_dir_path = Lproj(lang, output_path)
        l_xib_path = join(l_dir_path, name)
        l_old_path = join(l_dir_path, old_name)
        l_strings_path = Strings(name, l_dir_path)

        copy(l_xib_path, l_old_path)

        args = ["ibtool",
                "--previous-file", old_xib_path,
                "--incremental-file", l_old_path,
                "--strings-file", l_strings_path,
                "--localize-incremental",
                "--write", l_xib_path,
                xib_path]
        check_call(args)

    copy(xib['file'], xib['old'])  # changes are applied, mark original xib as old


def GenerateXibStrings(xib_path, output_path, langs):
    """
    Creates the .strings file for a xib and merges it with the localized .strings (if exists).
    """
    print "Generate strings from " + basename(xib_path)
    name = basename(xib_path)
    t_dir_path = mkdtemp()
    t_strings_path = Strings(name, t_dir_path)
    # Generate temporary strings file
    args = ["ibtool", "--generate-stringsfile", t_strings_path, xib_path]
    check_call(args)
    # Merge generated strings file with already localized strings files
    for lang in langs:
        print lang
        l_dir_path = Lproj(lang, output_path)
        l_strings_path = Strings(name, l_dir_path)
        MergeStrings(t_strings_path, l_strings_path)
    rmtree(t_dir_path)


def GenerateSourcesStrings(sources_paths, output_path, langs):
    """
    Creates the strings filr for given sources and merges it with the localized .strings (if exists).
    """
    print "Generate strings from " + ", ".join([basename(x) for x in sources_paths])
    t_dir_path = mkdtemp()
    args = ["genstrings", "-o", t_dir_path] + sources_paths
    check_call(args)
    for t_strings_path in [join(t_dir_path, x) for x in listdir(t_dir_path)]:
        for lang in langs:
            print lang
            l_dir_path = Lproj(lang, output_path)
            l_strings_path = Strings(t_strings_path, l_dir_path)
            MergeStrings(t_strings_path, l_strings_path)
    rmtree(t_dir_path)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Create localized xibs, or create .strings for sources.')

    parser.add_argument('mode', nargs=1, choices=('xibs', 'strings'), help="Type of localization file to generate.")
    parser.add_argument('--sources', action='store_true', help="When in strings mode, generate strings for sources. If neither --sources nor --xibs is specified, both are generated.")
    parser.add_argument('--xibs', action='store_true', help="When in strings mode, generate strings for xibs. If neither --sources nor --xibs is specified, both are generated.")

    args = parser.parse_args()

    if 'xibs' in args.mode:
        for xib in Xibs():
            LocalizeXib(xib['file'], xib['old'], xib['output'], Langs())
            print ""
    elif 'strings' in args.mode:
        if args.sources or not args.xibs:
            for sources in Sources():
                GenerateSourcesStrings(sources['files'], sources['output'], Langs() + [DevLang()])
                print ""
        if args.xibs or not args.sources:
            for xib in Xibs():
                GenerateXibStrings(xib['file'], xib['output'], Langs())
                print ""
