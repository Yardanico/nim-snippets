import os, osproc, json, strscans, strutils

# pkgs.json is packages.json from nimble
let data = parseFile("pkgs.json")

var cmds: seq[string]

for pkg in data:
  # Don't handle aliases
  if "alias" in pkg: continue
  let dir = "repos" / pkg["name"].getStr()
  var url = pkg["url"].getStr()
  # We already cloned it
  if existsDir(dir): continue
  var temp, subdir: string
  if scanf(url, "$+/$+?subdir=$+", temp, temp, subdir):
    url = url.replace("?subdir=" & subdir, "")

  let typ = pkg["method"].getStr()
  if typ == "git":
    cmds.add "git clone --depth=1 " & url & " " & dir
  elif typ == "hg":
    cmds.add "hg clone " & url & " " & dir
for cmd in cmds:
  echo cmd