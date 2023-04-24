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
let toBench = "c -d:release --compileOnly compiler/nim.nim"

let cmd = fmt"hyperfine -L compiler {namesList} 'testbins/{{compiler}} {toBench}' --runs 3 --export-json compiler.json"
echo execCmd(cmd)