#!/usr/bin/env python3
"""Fails when a String Catalog has a string that is untranslated in some language, or whose translation uses
different format placeholders from the source."""

import json
import re
import sys
from pathlib import Path

LANGUAGES = ["de", "es", "fr", "ja", "ko", "ru", "sv"]
CATALOGS = ["Blotter/Resources/Localizable.xcstrings", "Blotter/Resources/InfoPlist.xcstrings"]
PLACEHOLDER = re.compile(r"%(?:\d+\$)?(lld|ld|d|@|f|\.\d+f)")


def placeholders(text: str) -> list[str]:
    return sorted(PLACEHOLDER.findall(text))


def main() -> int:
    problems = []
    for path in CATALOGS:
        catalog = json.loads(Path(path).read_text(encoding="utf-8"))
        for key, entry in catalog["strings"].items():
            if entry.get("shouldTranslate") is False:
                continue
            localizations = entry.get("localizations", {})
            source = localizations.get("en", {}).get("stringUnit", {}).get("value", key)
            if path.endswith("InfoPlist.xcstrings"):
                source = entry.get("comment", source)
            for language in LANGUAGES:
                unit = localizations.get(language, {}).get("stringUnit")
                if not unit or unit.get("state") != "translated" or not unit.get("value"):
                    problems.append(f"{path}: {key!r} is not translated into {language}")
                elif placeholders(unit["value"]) != placeholders(source):
                    problems.append(f"{path}: {key!r} in {language} has placeholders {unit['value']!r}")
    for problem in problems:
        print(problem, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
