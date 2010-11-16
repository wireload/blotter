#!/usr/bin/env python

import sys
import Image


parts = []
part_names = []
out_name = "combined.png"
if len(sys.argv) == 10:
  part_names = sys.argv[1:]
elif len(sys.argv) == 11:
  out_name = sys.argv[1]
  part_names = sys.argv[2:]
else:
  raise Exception("usage: [output filename] <part-1> <part-2> ... <part-9>")

for arg in sorted(part_names):
  parts.append(Image.open(arg))
  print "opened %s (%dx%d)" % (arg, parts[-1].size[0], parts[-1].size[1])

width = sum(part.size[0] for part in parts[0:3])
height = sum(part.size[1] for part in parts[0:9:3])

combo_image = Image.new("RGBA", (width, height))

x, y = 0, 0
for n, part in enumerate(parts):
  print (x, y)
  # Leave the middle blank. The center piece doesn't work well with border-image.
  if n != 4:
    combo_image.paste(part, (x, y))
  x += parts[n % 3].size[0]
  if n % 3 == 2:
    x = 0
    y += part.size[1]

combo_image.save(out_name)
print "Created a %dx%d combination in %s" % (width, height, out_name)
