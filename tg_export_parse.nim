# A simple parser for Telegram chat history export feature
# Compile with nim c -d:release -d:danger tg_export_parse.nim
import htmlparser, xmltree, nimquery, strtabs, strutils, os, sequtils


proc parseFile(file: string): seq[tuple[name, text: string]] = 
  let html = loadHtml(file)
  let elems = html.querySelectorAll("div.default>div.body")

  var curname, text: string
  for elem in elems:
    var wasText = false
    for val in elem:
      if val.kind != xnElement: continue
      case val.attrs["class"]
      of "from_name": curname = val.innerText.strip
      of "text":
        wasText = true 
        text = val.innerText.replace("\n", " ").strip
      else: discard
    
    if not wasText: continue
    result.add (name: curname, text: text)
  result.deduplicate()

# Some ugly code to find all .html files (we can't just iterate
# over them in walkDir because the order is not guaranteed)
var maxI = 0
for (pc, path) in walkDir("."):
  var curI = 0
  let temp = path.splitFile()
  if temp.name == "messages": curI = 1
  else:
    if temp.name.startsWith("messages") and temp.ext == ".html":
      curI = parseInt temp.name.split("messages")[1]
  if curI > maxI: maxI = curI


var messages = parseFile("messages.html")

if maxI > 1:
  for i in 2 .. maxI:
    messages.add parseFile("messages" & $i & ".html")

var a = open("messages.txt", fmWrite)
for msg in messages:
  a.writeLine(msg.name & " : " & msg.text)
a.close()