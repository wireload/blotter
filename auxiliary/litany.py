#! /usr/bin/env python
# -*- coding: utf8 -*-

import argparse
import sys
import yaml
from codecs import open
import ply.lex as lex

COMPLEX_TEST = u'''
/*
     Meta.strings
     Blotter

     Created by Alexander Ljungberg on 12/02/2011.
     Copyright 2011 WireLoad. All rights reserved.
   */

/* App Store Description */
"App Store Description" = "Did you ever mark...

• Turn on ...";

/* App Store What's New */
"App Store What's New" = "New date ...
• Resolves...";

/* App Store Keywords */
"App Store Keywords" = "calendar, to do";'''

def tokenize_strings(data):
  ur"""

  Tokenize a .strings source file.

  >>> list(tokenize_strings('/* A comment */ "key" = "value";'))
  [LexToken(COMMENT,'/* A comment */',1,0), LexToken(QUOTED_STRING,'"key"',1,16), LexToken(EQUALS,'=',1,22), LexToken(QUOTED_STRING,'"value"',1,24), LexToken(SEMICOLON,';',1,31)]
  >>> repr(list(tokenize_strings(COMPLEX_TEST)))
  '[LexToken(COMMENT,u\'/*\\n     Meta.strings\\n     Blotter\\n\\n     Created by Alexander Ljungberg on 12/02/2011.\\n     Copyright 2011 WireLoad. All rights reserved.\\n   */\',2,1), LexToken(COMMENT,u\'/* App Store Description */\',4,145), LexToken(QUOTED_STRING,u\'"App Store Description"\',5,173), LexToken(EQUALS,u\'=\',5,197), LexToken(QUOTED_STRING,u\'"Did you ever mark...\\n\\n\\u2022 Turn on ..."\',5,199), LexToken(SEMICOLON,u\';\',5,236), LexToken(COMMENT,u"/* App Store What\'s New */",7,239), LexToken(QUOTED_STRING,u\'"App Store What\\\'s New"\',8,266), LexToken(EQUALS,u\'=\',8,289), LexToken(QUOTED_STRING,u\'"New date ...\\n\\u2022 Resolves..."\',8,291), LexToken(SEMICOLON,u\';\',8,319), LexToken(COMMENT,u\'/* App Store Keywords */\',10,322), LexToken(QUOTED_STRING,u\'"App Store Keywords"\',11,347), LexToken(EQUALS,u\'=\',11,368), LexToken(QUOTED_STRING,u\'"calendar, to do"\',11,370), LexToken(SEMICOLON,u\';\',11,387)]'
  """

  tokens = (
    'COMMENT',
    'EQUALS',
    'QUOTED_STRING',
    'SEMICOLON'
  )

  t_COMMENT = r'/\*([^*]+|\*[^/])*\*/'
  t_EQUALS = r'='
  t_QUOTED_STRING = r'''"([^\\"]+|\\"|\\\\)*"'''
  t_SEMICOLON = r';'

  # Define a rule so we can track line numbers
  def t_newline(t):
      r'\n+'
      t.lexer.lineno += len(t.value)

  # A string containing ignored characters (spaces and tabs)
  t_ignore  = ' \t'

  # Error handling rule
  def t_error(t):
      print "Illegal character '%s'" % t.value[0]
      t.lexer.skip(1)

  # Build the lexer
  lexer = lex.lex()

  # Give the lexer some input
  lexer.input(data)

  # Tokenize
  while True:
      tok = lexer.token()
      if not tok: break      # No more input
      yield tok

class Litany(object):
  def __init__(self, config_file):
    self.config = yaml.load(config_file.read())

  def write(self, output, language):
    output.write(self.config.get('project', {}).get('comment', '/* Combined.string */') + "\n")

    for file in self.config.get('strings', []):
      self.write_from_file(language, file['path'], file['id'], file.get('comment'), file.get('skip', []))

  def write_from_file(self, language, path, id, comment, skip_list):
      path = path % {'lang': language}
      infile = open(path, "rb", 'utf-16')

      if comment:
        output.write("""/*\n    %s\n\n    (Source = '%s')\n*/\n\n""" % (comment, path))
      else:
        output.write("""/*\n    '%s'\n*/\n\n""" % path)

      print id, path
      last_comment = None
      last_key = None
      last_value = None
      expected = 'key'

      for token in tokenize_strings(infile.read()):
        if token.type == 'COMMENT':
          last_comment = token.value
          continue

        if expected == 'key':
          if token.type != 'QUOTED_STRING':
            raise "Expected KEY at %s:%d" % (path, token.lineno)
          last_key = token.value
          expected = 'equals'
        elif expected == 'equals':
          if token.type != 'EQUALS':
            raise "Expected '=' at %s:%d" % (path, token.lineno)
          expected = 'value'
        elif expected == 'value':
          if token.type != 'QUOTED_STRING':
            raise "Expected VALUE at %s:%d" % (path, token.lineno)
          last_value = token.value
          expected = 'semicolon'
        elif expected == 'semicolon':
          if token.type != 'SEMICOLON':
            raise "Expected ';' at %s:%d" % (path, token.lineno)

          bare_key = last_key[1:-1]
          if not bare_key in skip_list:
            # Output our key value pair.
            if last_comment:
              output.write(last_comment + "\n")

            key = u'"%s.%s"' % (id, bare_key)
            output.write(u'%s = %s;\n' % (key, last_value))

          expected = 'key'

      if expected != 'key':
        raise u"Unexpected EOF after key %s" % last_key

      output.write("\n")
      


if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Combine .strings file into a single global .strings file for translation.')

  parser.add_argument('-c', '--config', metavar='FILE', nargs='?', type=argparse.FileType('r'), default=None, help='Configuration file to read (default litany.yml).')
  parser.add_argument('action', nargs=1, choices=('create_global', 'process_global'), help="Action to perform: create_global generates the single .strings file and process_global reads it back for a given language.")
  parser.add_argument('strings_file', action='store', nargs=1, help="The output (when using create_global) or input (when using process_global) .strings file.")
  parser.add_argument('language', action='store', help="The language code to work with. When in create_global, this language will be used as the basis. When in process_global, this language will be used as the destination.")

  args  = parser.parse_args()

  litany = Litany(args.config or open('litany.yml', 'r', 'utf-8'))
  if args.action[0] == 'create_global':
    of = args.strings_file[0]
    output = sys.stdout if of == '-' else open(args.strings_file[0], 'wb', 'utf-16')
    litany.write(output, args.language)
    output.close()

  