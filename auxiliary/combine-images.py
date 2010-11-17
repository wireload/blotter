#!/usr/bin/env python

"""

Combine a nine-part image into a single merged file for use with border-image.

"""

from __future__ import division

import argparse
import Image
import sys
import math

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
    # The top 3 pieces define the width of each column.
    part_width = parts[n % 3].size[0]
    # The leftmost 3 pieces define the height of each row.
    part_height = parts[3 * int(math.floor(n / 3))].size[1]

    print (x, y, part_width, part_height)
    if not args.empty or n != 4:
      if part.size != (part_width, part_height):
        part = part.resize((part_width, part_height), Image.BICUBIC)
      combo_image.paste(part, (x, y))

    x += part_width
    if n % 3 == 2:
      x = 0
      y += part_height

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
