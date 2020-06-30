#[
  A simple (script? program? app?) I hacked together to test Karax.
  Allows to go to newer / older images than the current one (starts with)
  the ID specified in curId.
  prnt.sc - quite popular service for image hosting, used by their own tool
  called Lightshot. All IDs on prnt.sc are actually just Base36 of the numbers,
  so you can easily get images sequentially
]#

import std / [strutils, random, sugar, base64, strformat]

include karax / prelude
import karax / kajax

const 
  Digits = "0123456789abcdefghijklmnopqrstuvwxyz"

proc reverse(a: string): string =
  result = newString(a.len)
  for i, c in a:
    result[a.high - i] = c

proc toBase36(num: SomeNumber): string =
  var tmp = abs(num)
  var s = ""
  while tmp > 0:
    s.add Digits[int(tmp mod 36)]
    tmp = tmp div 36
  result.add s.reverse()

proc fromBase36(str: string): BiggestInt =
  for chr in str:
    result = result * 36 + Digits.find(chr.toLowerAscii())

proc nextId(str: string): string = 
  toBase36(fromBase36(str) + 1)

proc prevId(str: string): string = 
  toBase36(fromBase36(str) - 1)

proc getImgUrl(url: kstring, cb: (string) -> void) = 
  ajaxGet(url, @[], cont = proc (resp: int, cont: kstring) =
    if resp == 200:
      let urli = $cont.split("no-click screenshot-image\" src=\"")[1].split("\"")[0]
      # Special check for st.prntscr.com
      if urli.startsWith("//st"): 
        cb("https://" & urli[2..^1])
      else:
        cb(urli)
  )

var 
  imgData = ""
  imgReady = false
  curId = "t9aoet"

proc fetchUrl(url: kstring) = 
  imgReady = false
  getImgUrl(url, proc (imgUrl: string) = 
    imgData = imgUrl
    imgReady = true
  )

proc getUrl(next = true): string = 
  let url = "prnt.sc"
  curId = if next: nextId(curId) else: prevId(curId)
  result = fmt"https://{url}/{curId}"

proc createDom(): VNode = 
  result = buildHtml(tdiv):
    if imgReady:
      img(src=imgData, alt="Nim image")
    
    br()

    for f in ["Previous", "Next"]:
      button(`type`="button"):
        text f
        proc onclick(ev: Event; n: VNode) = 
          fetchUrl(if f == "Previous": getUrl(false) else: getUrl())

setRenderer(createDom)