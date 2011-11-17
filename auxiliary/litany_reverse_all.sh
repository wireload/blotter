#!/bin/sh
# Run process_global for all the languages. lang_files.zip from MyGengo is expected to be unzipped in the current folder.

python auxiliary/litany.py process_global lang_files/de/blotter.strings de
python auxiliary/litany.py process_global lang_files/es/blotter.strings es
python auxiliary/litany.py process_global lang_files/fr/blotter.strings fr
python auxiliary/litany.py process_global lang_files/ko/blotter.strings ko
# python auxiliary/litany.py process_global lang_files/ru/blotter.strings ru
python auxiliary/litany.py process_global lang_files/sv/blotter.strings sv

