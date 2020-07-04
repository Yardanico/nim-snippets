# TODO: Handle comments before requires
import std / [
  os, 
  strutils, sequtils, strformat,
  tables, json
]

import npeg
import npeg/lib/utf8

type
  PackageData = object
    pkgs: seq[string]
    path: string
    author: string
    license: string
    version: string

let parser = peg("file", req: PackageData):

  nl <- {' ', '\t', '\9' .. '\13'}

  entry <- '"' * >*(Print - '"') * '"':
    req.pkgs.add $1
  
  requires <- *nl * i"requires" * *nl * ?':' * *nl * ?'(' * *(entry * ?',' * *nl) * ?')'

  parseField(name) <- ?*nl * name * *nl * (':' | '=') * *nl * '"' * >*(utf8.any - '"') * '"'

  license <- parseField("license"):
    req.license = $1
  
  author <- parseField("author"):
    req.author = ($1).replace("'", "\\'")
  
  version <- parseField("version"):
    req.version = $1

  file <- *@(version | author | license | requires)

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
  var pkgData = PackageData(path: path)
  var m = parser.match(data, pkgData)
  if m.ok != true:
    raise newException(ValueError, "Can't parse " & path)
  var pkgs: seq[string]
  for pkg in pkgData.pkgs:
    # Even after parsing we might have entries with multiple pkgs
    let splut = pkg.split(",").filterIt(it != "").mapIt(it.strip())
    for temp in splut:
      var name = stripThings(temp)
      # Replace the alias
      if name in aliases:
        name = aliases[name]
      # unixcmd was commented
      if name notin ["nim", "nimrod", "unixcmd"]: pkgs.add name
  # update with new packages
  pkgData.pkgs = pkgs.deduplicate()
  graph[normalize(pkgname)] = pkgData

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

  # .dot graphviz output
  when false:
    var outf = open("deps_nothing.dot", fmWrite)
    outf.writeLine "digraph data {"
    for key, val in graph:
      # Package doesn't depend on anything
      if val.pkgs.len == 0:
        outf.writeLine "\"$1\";" % [key]
      else:
        for pkg in val.pkgs:
          outf.writeLine "\"$1\" -> \"$2\";" % [key, pkg]
    outf.writeLine "}"
    outf.close()
  var
    createStmts: seq[string]
    relationStmts: seq[string]
  
  var nameToId = newTable[string, string](2048)
  var authorToId = newTable[string, string](512)
  var i = 0
  
  template getId: string = 
    let strId = "id" & $i
    inc i
    strId
  # two passes:
  # first one: populate all create statements with IDs and authors
  for key, val in graph:
    let strId = getId()
    nameToId[key] = strId
    var props = ""
    props.add &"pkgname: '{key}', "
    # props.add &"author: '{val.author}', "
    props.add &"license: '{val.license}', "
    props.add &"version: '{val.version}'"
    createStmts.add fmt"create ({strId}:package {{{props}}})"
    if val.author notin authorToId:
      let authorId = getId()
      createStmts.add fmt"create ({authorId}:author {{name: '{val.author}'}})"
      authorToId[val.author] = authorId
    else:
      let authorId = authorToId[val.author]
      relationStmts.add fmt"create ({strId})-[:authored_by]->({authorId})"
  # second pass: populate relations
  for key, val in graph:
    for pkg in val.pkgs:
      let varname = nameToId[key]
      if pkg in nameToId:
        relationStmts.add fmt"create ({varname})-[:depends_on]->({nameToId[pkg]})"
      # for non-nimble dependencies (github, etc)
      elif "://" in pkg:
        let strId = getId()
        createStmts.add fmt"create ({strId}:package {{pkgname: '{pkg}'}})"
        relationStmts.add fmt"create ({varname})-[:depends_on]->({strId})"
      else:
        quit pkg
  
  when false:
    for key, val in graph:
      # Sanity check to see if we have dependencies which are not in our table
      # Don't check https
      if "://" notin pkg and pkg notin graph:
        echo "Can't find ", pkg
        echo key, " ", val
  
  var outf = open("populate.cypher", fmWrite)

  for create in createStmts:
    outf.writeLine create
  
  for relate in relationStmts:
    outf.writeLine relate
  
  outf.close()
  echo graph.len

main()