# This was written in 2017 and I just decided to 
# save this in a better place than just Gist.
# This program does a simple thing: it reads all pixel placing
# events from Reddit's r/place (it took place in April 2017)
# and saves the resulting image as out.png with the help of NiGui
# You can download the diffs.bin data from
# http://web.archive.org/web/*/http://abra.me/place/diffs.bin
# (for example http://web.archive.org/web/20170404153119/http://abra.me/place/diffs.bin)
# sine the original website doesn't have these
# For more info read
# https://www.reddit.com/r/place/comments/62z2uu/rplace_archive_update_and_boardbitmap_description/
# File from https://www.reddit.com/r/place/comments/6396u5/rplace_archive_update/
import nigui, streams

type
  ColorId = range[0..15]

proc toRgb(c: ColorId): Color = 
  case c
  of 0: rgb(255, 255, 255)
  of 1: rgb(228, 228, 228)
  of 2: rgb(136, 136, 136)
  of 3: rgb(34, 34, 34)
  of 4: rgb(255, 167, 209)
  of 5: rgb(229, 0, 0)
  of 6: rgb(229, 149, 0)
  of 7: rgb(160, 106, 66)
  of 8: rgb(229, 217, 0)
  of 9: rgb(148, 224, 68)
  of 10: rgb(2, 190, 1)
  of 11: rgb(0, 211, 211)
  of 12: rgb(0, 131, 199)
  of 13: rgb(0, 0, 234)
  of 14: rgb(207, 110, 228)
  of 15: rgb(130, 0, 128)

proc main = 
  app.init()
  
  let data = newFileStream("diffs.bin", fmRead)
  var resultImage = newImage()
  resultImage.resize(1000, 1000)
  var pixels: array[1000, array[1000, ColorId]]

  var i = 0
  # 11_968_422 events
  while not data.atEnd:
    inc i 
    let
      timestamp = data.readInt32()
      x = data.readInt32()
      y = data.readInt32()
      color = data.readInt32()
    pixels[x][y] = color
  echo "Total num of events - ", i

  data.close()

  for x, data in pixels:
    for y, color in data:
      resultImage.canvas.setPixel(x, y, color.toRgb)
    
  resultImage.saveToPngFile("out.png")

main()