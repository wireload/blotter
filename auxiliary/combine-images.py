#!/usr/bin/env python

"""

Combine a nine-part image into a single merged file for use with border-image.

"""

import argparse
import Image
import sys

def combine(args):
  parts = []
  for arg in sorted(args.parts):
    parts.append(Image.open(arg))
    print "opened %s (%dx%d)" % (arg, parts[-1].size[0], parts[-1].size[1])

  width = sum(part.size[0] for part in parts[0:3])
  height = sum(part.size[1] for part in parts[0:9:3])

  combo_image = Image.new("RGBA", (width, height))

  x, y = 0, 0
  for n, part in enumerate(parts):
    print (x, y)
    if not args.empty or n != 4:
      combo_image.paste(part, (x, y))
    x += parts[n % 3].size[0]
    if n % 3 == 2:
      x = 0
      y += part.size[1]

  combo_image.save(args.outfile)
  print "Created a %dx%d combination in %s" % (width, height, args.outfile)

if __name__ == '__main__':
  parser = argparse.ArgumentParser(description=__doc__)

  parser.add_argument('--outfile', metavar='FILE', default='combined.png',
                      help='name to save the combined image as. Default: combined.png')
  parser.add_argument('--empty', action='store_true',
                      help='if set, leave the middle of the image blank instead of inserting part 5')
  parser.add_argument('parts', metavar='PARTS', nargs=9,
                      help='the nine images to combine')

  args = parser.parse_args()
  combine(args)
