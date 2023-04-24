import ./common

import std/[strutils, strformat, os, osproc]

var myVersions = versions
myVersions.add ({pgo}, "pgo")


var names: seq[string]
for comp in Compiler:
  for version in myVersions:
    let binName = versionName(comp, version)
    names.add binName

let namesList = names.join(",")

#let cmd = paramStr(1)
let toBench = "c -d:release --compileOnly tests/tests.nim"
let name = "regex.json"

let cmd = fmt"hyperfine -L compiler {namesList} '/home/dian/Things/nim/testbins/{{compiler}} {toBench}' --runs 3 --export-json {name}"
echo execCmd(cmd)
copyFile(getCurrentDir() / name, "/home/dian/Projects/nim-snippets/pgo/results/" / name)