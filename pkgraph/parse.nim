# TODO: Handle comments before requires
import os, strutils, sequtils, tables, json
import npeg

type
  PackageData = object
    pkgs: seq[string]
    path: string

let parser = peg("file", req: seq[string]):
  nl <- {' ', '\t', '\9' .. '\13'}

  entry <- '"' * >*(Print - '"') * '"':
    req.add $1

  requires <- i"requires" * *nl * ?':' * *nl * ?'(' * *(entry * ?',' * *nl) * ?')' * *nl

  file <- *@requires

# For resolving aliases
let x = parseFile("pkgs.json")
var aliases = newTable[string, string]()
for obj in x.elems:
  if "alias" in obj:
    aliases[obj["name"].getStr()] = obj["alias"].getStr()

proc normalize(s: string): string =
  s.toLowerAscii().replace("_", "")

proc stripThings(data: string): string =
  # nim >= 0.18.0    https://github.com/test/abcd#12312412  nim@#head nim#123213
  if "://" in data and not anyIt({'>', '<', '#', '@'}, it in data):
    result = data.split(".git")[0].split("#")[0]
  else:
    result = data.split({'>', '<', '=', '@', '#', ' '})[0].strip()
  result = result.normalize()

proc main =
  var graph = newTable[string, PackageData](2048)
  for file in walkDirRec("repos"):
    let (dir, name, ext) = file.splitFile()
    if ext notin [".nimble", ".babel"]: continue
    if ["examples", "test"].anyIt(it in dir):
      # Ugly, but we don't want "test" .nimble files
      if name notin ["findtests", "litestore", "ptest", "testrunner", "testutils", "testify"]:
        #echo "Skipping ", file
        continue
    #echo dir / name & ext
    let data = readFile(file)
    var pkgsRaw: seq[string]
    var m = parser.match(data, pkgsRaw)
    if m.ok != true:
      raise newException(ValueError, "Can't parse " & file)
    var pkgs: seq[string]
    for pkg in pkgsRaw:
      # Even after parsing we might have entries with multiple pkgs
      let splut = pkg.split(",").filterIt(it != "").mapIt(it.strip())
      for temp in splut:
        var name = stripThings(temp)
        # Replace the alias
        if name in aliases:
          name = aliases[name]
        # unixcmd was commented
        if name notin ["nim", "nimrod", "unixcmd"]: pkgs.add name
    graph[normalize(name)] = PackageData(path: file, pkgs: pkgs.deduplicate())

  var outf = open("deps_nothing.dot", fmWrite)
  outf.writeLine "digraph data {"
  for key, val in graph:
    # Package doesn't depend on anything
    if val.pkgs.len == 0:
      outf.writeLine "\"$1\";" % [key]
    else:
      for pkg in val.pkgs:
        outf.writeLine "\"$1\" -> \"$2\";" % [key, pkg]
    # Sanity check to see if we have dependencies which are not in our table
    for v in val.pkgs:
      # Don't check https
      if "://" notin v and v notin graph:
        echo "Can't find ", v
        echo key, " ", val
  outf.writeLine "}"
  outf.close()
  echo graph.len

main()