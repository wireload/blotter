#! /usr/bin/env python
# -*- coding: utf8 -*-

import argparse
import codecs
import os
import ply.lex as lex
import sys
import yaml

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

  t_COMMENT = ur'/\*([^*]+|\*[^/])*\*/'
  t_EQUALS = ur'='
  t_QUOTED_STRING = ur'''"([^\\"]+|\\n|\\"|\\\\)*"'''
  t_SEMICOLON = ur';'

  # Define a rule so we can track line numbers
  def t_newline(t):
      ur'\n+'
      t.lexer.lineno += len(t.value)

  # A string containing ignored characters (spaces and tabs)
  t_ignore  = u' \t'

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
      if not tok:
        break      # No more input
      yield tok


def pairs_of_strings(file_name, data):
  preceeding_comments = []
  last_key = None
  last_value = None
  expected = 'key'

  for token in tokenize_strings(data):
    if token.type == 'COMMENT':
      preceeding_comments.append(token.value)
      continue

    if expected == 'key':
      if token.type != 'QUOTED_STRING':
        raise "Expected KEY at %s:%d" % (file_name, token.lineno)
      last_key = token.value
      expected = 'equals'
    elif expected == 'equals':
      if token.type != 'EQUALS':
        raise "Expected '=' at %s:%d" % (file_name, token.lineno)
      expected = 'value'
    elif expected == 'value':
      if token.type != 'QUOTED_STRING':
        raise "Expected VALUE at %s:%d" % (file_name, token.lineno)
      last_value = token.value
      expected = 'semicolon'
    elif expected == 'semicolon':
      if token.type != 'SEMICOLON':
        raise "Expected ';' at %s:%d" % (file_name, token.lineno)

      bare_key = last_key[1:-1]
      yield {'key': bare_key, 'comments': preceeding_comments, 'value': unicode(last_value)}
      preceeding_comments = []
      expected = 'key'
  if expected != 'key':
    raise u"Unexpected EOF after key %s" % last_key


class Litany(object):
  def __init__(self, config_file):
    self.config = yaml.load(config_file.read())

  def write(self, output, language):
    output.write(self.config.get('project', {}).get('comment', '/* Combined.string */') + "\n")

    for file in self.config.get('strings', []):
      self.write_from_file(language, file['path'], file['id'], file.get('comment'), file.get('skip', []))

  def write_from_file(self, language, path, id, comment, skip_list):
      path = path % {'lang': language}
      infile = codecs.open(path, "rb", 'utf-16')

      if comment:
        output.write(u"""/*\n    %s\n\n    (Source = '%s')\n*/\n\n""" % (comment, path))
      else:
        output.write(u"""/*\n    '%s'\n*/\n\n""" % path)

      print id, path

      for pair in pairs_of_strings(path, infile.read()):
          if not pair['key'] in skip_list:
            # Output our key value pair.
            if pair.get('comments'):
              output.write(pair['comments'][0] + "\n")

            key = u'"%s.%s"' % (id, pair['key'])
            output.write(u'%s = %s;\n' % (key, pair['value']))

      output.write("\n")

  def process(self, input, language):
    # TODO How do we write this without losing the whitespace formatting of the original .strings files?

    pairs = list(pairs_of_strings('<input>', input.read()))

    for file in self.config.get('strings', []):
      self.process_to_file(pairs, file['path'] % {'lang': language}, file['id'], file.get('skip', []))

  def process_to_file(self, pairs, path, id, skip_list):
    # First read the destination so that we can recreate it.
    with codecs.open(path, "rb", 'utf-16') as target_read:
      existing_pairs = list(pairs_of_strings(path, target_read.read()))

    print "Updating %s with %d keys..." % (path, len(existing_pairs))
    matches = 0
    new_values = 0
    # Now write out each key and comment in the same order, substituting values from pairs when possible.
    with codecs.open(path, "wb", 'utf-16') as target_write:
      for pair in existing_pairs:
        for comment in pair['comments']:
          target_write.write(comment + u'\n')
        value = pair['value']

        if not pair['key'] in skip_list:
          source_key = "%s.%s" % (id, pair['key'])
          for source_pair in pairs:
            if source_pair['key'] == source_key:
              value = source_pair['value']
              matches += 1
              if value != pair['value']:
                new_values += 1
              break
          else:
            #print u"Did not replace %s = %s" % (pair['key'], value)
            pass

        output_line = u'"%s" = %s;\n\n' % (pair['key'], value)
        target_write.write(output_line)

    print "Found %d matching keys (%d updated)" % (matches, new_values)

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description='Combine .strings file into a single global .strings file for translation.')

  parser.add_argument('-c', '--config', metavar='FILE', nargs='?', type=argparse.FileType('r'), default=None, help='Configuration file to read (default litany.yml).')
  parser.add_argument('action', nargs=1, choices=('create_global', 'process_global'), help="Action to perform: create_global generates the single .strings file and process_global reads it back for a given language.")
  parser.add_argument('strings_file', action='store', nargs=1, help="The output (when using create_global) or input (when using process_global) .strings file.")
  parser.add_argument('language', action='store', help="The language code to work with. When in create_global, this language will be used as the basis. When in process_global, this language will be used as the destination.")

  args = parser.parse_args()

  litany = Litany(args.config or codecs.open(os.path.join(os.path.dirname(__file__), 'litany.yml'), 'r', 'utf-8'))
  if args.action[0] == 'create_global':
    of = args.strings_file[0]
    output = sys.stdout if of == '-' else codecs.open(of, 'wb', 'utf-16')
    litany.write(output, args.language)
    output.close()
  else:
    inpf = args.strings_file[0]
    input = sys.stdin if inpf == '-' else codecs.open(inpf, 'rb', 'utf-8')
    litany.process(input, args.language)
