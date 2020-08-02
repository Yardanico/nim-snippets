import std / [os, osproc, json, strscans, strutils, strformat]

# https://raw.githubusercontent.com/nim-lang/packages/master/packages.json
let data = parseFile("packages.json")

var cmds: seq[string]

for pkg in data:
  # Don't handle aliases
  if "alias" in pkg: continue
  let dir = "repos" / pkg["name"].getStr()
  var url = pkg["url"].getStr()
  var temp, subdir: string
  if scanf(url, "$+/$+?subdir=$+", temp, temp, subdir):
    url = url.replace("?subdir=" & subdir, "")
  
  # We already cloned it
  if dir.dirExists():
    # Add subdir info to an existing repo
    if subdir != "":
      var f = open(dir / "subdir.meta", fmAppend)
      f.writeLine(subdir)
      f.close()
    continue

  let typ = pkg["method"].getStr()
  if typ == "git":
    var cmd = "git clone --depth=1 " & url & " " & dir
    if subdir != "":
      cmd &= fmt" ; echo '{subdir}' >> {dir}/subdir.meta"
    cmds.add cmd
  elif typ == "hg":
    cmds.add "hg clone " & url & " " & dir

discard execProcesses(cmds)