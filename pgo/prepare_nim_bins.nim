#[
  GCC:
    release - nim_gcc_rel
    danger - nim_gcc_dan
    release lto - nim_gcc_rel_lto
    danger lto - nim_gcc_dan_lto
    danger lto pgo - nim_gcc_pgo

  Clang:
    release - nim_clang_rel
    danger - nim_clang_dan
    release lto - nim_clang_rel_lto
    danger lto - nim_clang_dan_lto
    danger lto pgo - nim_clang_pgo
]#

import std/[strformat, strutils, osproc]

type
  Flags = enum
    release, danger, lto, pgo
  Compiler = enum
    gcc, clang

let versions = @[
  ({release}, "rel"), 
  ({danger}, "dan"),
  ({release, lto}, "rel_lto"), 
  ({danger, lto}, "dan_lto"),
  #({danger, pgo}, "_pgo") - compiled manually for now :)
]

const NimBin = "nim_pgo_clang"

for comp in Compiler:
  for version in versions:
    let binName = fmt"nim_{comp}_{version[1]}"
    var flags = @["c", fmt"--cc:{comp}", "--verbosity:0"]
    for flag in version[0]:
      flags.add case flag
        of release: "-d:release"
        of danger: "-d:danger"
        of lto: "--passC:-flto --passL:-flto"
        # todo
        of pgo: ""
    flags.add fmt"-o:{binName}"
    flags.add "compiler/nim.nim"
    echo fmt"Building {binName}"
    let cmd = NimBin & " " & flags.join(" ")
    doAssert execCmd(cmd) == 0