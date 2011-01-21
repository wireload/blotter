#! /usr/bin/python

import os
import subprocess

def Localizations():
    dirs = []
    root_dir = os.curdir
    for path in os.listdir(root_dir):
        path = os.path.join(root_dir, path)
        if (os.path.isdir(path)) and os.path.splitext(path)[1] == ".lproj":
            dirs.append(path)
    return dirs

def ExtractLocaleName(path):
    return os.path.splitext(os.path.basename(path))[0]

def UpdateMainMenu(path):
    xibs = ["CalendarsPrefPaneView", "GeneralPrefPaneView", "PositionPrefPaneView"] # without extensions
    for xib in xibs:
        xib_name = xib + ".xib"
        strings_name = xib + ".strings"
        args = ["ibtool",
                "--strings-file", os.path.join(path, strings_name),
                "--write", os.path.join(path, xib_name),
                os.path.join("English.lproj", xib_name)]
        subprocess.call(args)

def UpdateSourcesStrings(path):
    "Conent of the old .strings file will be deleted!"
    sources = ["GeneralPrefController.m",
               "PositionPrefController.m",
               "CalendarsPrefController.m"]
    args = ["genstrings"] + sources + ["-o", os.path.join(os.curdir, path)]
    subprocess.call(args)

if __name__ == '__main__':
    localizations = Localizations()
    for path in localizations:
        UpdateMainMenu(path)
        #UpdateSourcesStrings(path)
        
