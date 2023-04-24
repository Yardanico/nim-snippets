import std/strformat

type
  Flags* = enum
    release, danger, lto, pgo
  Compiler* = enum
    gcc, clang

const versions* = @[
  ({release}, "rel"), 
  ({danger}, "dan"),
  ({release, lto}, "rel_lto"), 
  ({danger, lto}, "dan_lto"),
  #({danger, pgo}, "_pgo") - compiled manually for now :)
]

proc versionName*(comp: Compiler, ver: (set[Flags], string)): string =
  fmt"nim_{comp}_{ver[1]}"