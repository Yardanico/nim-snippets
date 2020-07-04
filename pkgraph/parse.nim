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

proc findNimble(path: string): string = 
  for (kind, file) in walkDir(path):
    let (dir, name, ext) = file.splitFile()
    if ext in [".nimble", ".babel"]:
      result = file
      break

proc addNimbleToGraph(graph: TableRef[string, PackageData], pkgname, path: string) = 
  let data = readFile(path)
  var pkgsRaw: seq[string]
  var m = parser.match(data, pkgsRaw)
  if m.ok != true:
    raise newException(ValueError, "Can't parse " & path)
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
  graph[normalize(pkgname)] = PackageData(path: path, pkgs: pkgs.deduplicate())

proc main =
  var graph = newTable[string, PackageData](2048)
  for (kind, repoDir) in walkDir("repos"):
    # iterate over every dir in repos
    let pkgName = repoDir.splitFile()[1]
    if kind != pcDir: continue

    var handledSubdir = false
    # for each file in repo dir
    for (kind, repoFile) in walkDir(repoDir):
      let (dir, name, ext) = repoFile.splitFile()
      # handle subdir.meta
      if (name & ext) == "subdir.meta":
        # for each possible subdir
        for subDir in lines(repoFile):
          # find nimble file in that subdir, parse it and add to "graph"
          let repoSubdir = repoDir / subDir
          let nimbleFile = findNimble(repoSubdir)
          if nimbleFile == "":
            echo repoSubdir
            quit "Can't find .nimble file"
          let subdirPkgName = repoSubdir.splitFile()[1]
          graph.addNimbleToGraph(subdirPkgName, nimbleFile)
        handledSubdir = true
        break
    if not handledSubdir:
      let nimbleFile = findNimble(repoDir)
      # shouldn't happen since we must find a 
      if nimbleFile == "":
        echo repoDir
        quit "Can't find .nimble file"
      graph.addNimbleToGraph(pkgName, nimbleFile)

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