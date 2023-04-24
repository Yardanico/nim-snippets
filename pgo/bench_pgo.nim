import ./common

import std/[strutils, strformat, osproc]

var myVersions = versions
myVersions.add ({pgo}, "pgo")


var names: seq[string]
for comp in Compiler:
  for version in myVersions:
    let binName = versionName(comp, version)
    names.add binName

let namesList = names.join(",")

let cmd = fmt"hyperfine -L compiler {namesList} 'testbins/{{compiler}} c -f -d:release --compileOnly compiler/nim.nim' --runs 3 --export-json testout.json"
echo execCmd(cmd)