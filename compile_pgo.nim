# bad code ahead, you've been warned!
import std/[os, osproc, strutils, strformat, tempfiles]

import pkg/shell
type
  CompileEntry = tuple
    url, file: string
    nimble, orc: bool

# repo, path to file to compile, can compile with orc?
const ToCompile: seq[CompileEntry] = @[
  ("https://github.com/mratsim/Arraymancer", "tests/tests_cpu.nim", true, true),
  ("https://github.com/zevv/npeg", "tests/tests.nim", true, true),
  ("https://github.com/planety/prologue", "examples/todoapp/app.nim", true, true),
  ("https://github.com/zedeus/nitter", "src/nitter.nim", true, true),
  ("https://github.com/rlipsc/polymorph", "tests/testall.nim", true, true),
  ("https://github.com/nitely/nim-regex", "tests/tests.nim", true, true),
  ("https://github.com/nim-lang/nim", "compiler/nim.nim", false, true)
]


var 
  i = 1
  isGcc = true

proc profileName(tmpDir: string, name: string) =
  let val = 
    if isGcc:
      tmpDir / "profiles" / (name & $i)
    else:
      tmpDir / "profiles" / (name & $i & ".profraw")
  putEnv(if isGcc: "GCCPROF" else: "LLVM_PROFILE_FILE", val)
  inc i

proc compilePgo(compBin, tmpDir, name, filePath: string, orc: bool) = 
  # We also compile without danger so that the paths related
  # to debug code (assertions, safety checks, etc) also get optimized
  profileName(tmpDir, name)
  doAssert execCmd(fmt"{compBin} c -f --compileOnly {filePath}") == 0
  profileName(tmpDir, name)
  doAssert execCmd(fmt"{compBin} c -f --compileOnly -d:danger {filePath}") == 0
  if orc:
    profileName(tmpDir, name)
    doAssert execCmd(fmt"{compBin} c -f --compileOnly -d:orc {filePath}") == 0
    profileName(tmpDir, name)
    doAssert execCmd(fmt"{compBin} c -f --compileOnly -d:orc -d:danger {filePath}") == 0


proc buildCompilerFirst(tmpDir, binName: string): string = 
  let args = 
    if not isGcc:
      @[
        "c", "-d:danger", "--cc:clang",
        "--passC:-fprofile-instr-generate", "--passL:-fprofile-instr-generate",
        "--passC:-flto", "--passL:-flto",
        "-o:bin/" & binName, "compiler/nim.nim"
      ]
    else:
      @[
        "c", "-d:danger", "--cc:gcc",
        fmt"--passC:-fprofile-generate={tmpDir}/profiles/%q{{GCCPROF}}", 
        fmt"--passL:-fprofile-generate={tmpDir}/profiles/%q{{GCCPROF}}",
        "--passC:-flto", "--passL:-flto",
        "-o:bin/" & binName, "compiler/nim.nim"
      ]
    
  doAssert execCmd("nim " & args.join(" ")) == 0
  result = expandFilename("bin/" & binName)

proc buildCompilerSecond(tmpDir, binName: string, profs: seq[string]) =   
  let args = 
    if not isGcc:
      @[
        "c", "-d:danger", "--cc:clang",
        fmt"--passC:-fprofile-instr-use={tmpDir}/main.profdata", 
        fmt"--passL:-fprofile-instr-use={tmpDir}/main.profdata",
        "--passC:-flto", "--passL:-flto",
        "-o:bin/" & binName, "compiler/nim.nim"
      ]
    else:
      @[
        "c", "-d:danger", "--cc:gcc",
        fmt"--passC:-fprofile-use={tmpDir}/profiles/main --passC:-fprofile-correction", 
        fmt"--passL:-fprofile-use={tmpDir}/profiles/main --passL:-fprofile-correction",
        "--passC:-flto", "--passL:-flto",
        "-o:bin/" & binName, "compiler/nim.nim"
      ]

  doAssert execCmd("nim " & args.join(" ")) == 0

proc main = 
  # build stage 1 pgo compiler
  let origDir = getCurrentDir()
  let tmpDir = createTempDir("nim_pgo", "")
  let path1 = buildCompilerFirst(tmpDir, "nim_temp_pgo")
  setCurrentDir(tmpDir)

  # so we don't pollute the default nimble dir
  putEnv("NIMBLE_DIR", tmpDir / "nimble")
  # compile and generate profiles for all projects
  for entry in ToCompile:
    let entryName = entry.url.split("/")[^1]
    # depth=1 so no submodules, maybe also an additional bool?
    doAssert execCmd(fmt"git clone --depth=1 {entry.url}") == 0
    setCurrentDir(entryName)
    # if the project has nimble deps, install them
    if entry.nimble:
      doAssert execCmd(fmt"nimble install -y") == 0
    compilePgo(path1, tmpDir, entryName, entry.file, entry.orc)
    setCurrentDir("..")
  
  # find names for all the generated profiles
  var profs: seq[string]
  if not isGcc:
    for pc in walkDir(tmpDir / "profiles"):
      if pc.kind == pcFile and pc.path.endsWith(".profraw"):
        profs.add pc.path
    let profsStr = profs.join(" ")
    doAssert execCmd(fmt"llvm-profdata merge {profsStr} -output {tmpDir}/main.profdata") == 0
  else:
    # I have no idea how to fix GCC putting files into /tmp/folder/profiles/folder/profiles
    # instead of /tmp/folder/profiles
    for pc in walkDir(tmpDir / "profiles" / tmpDir / "profiles"):
      if pc.kind == pcDir:
        profs.add pc.path

    let profsStr = profs.join(" ")
    doAssert execCmd(fmt"/home/dian/Things/nim/gcov-tool.sh merge {profsStr} --output {tmpDir}/profiles/main") == 0
  
  # build stage 2 pgo compiler
  setCurrentDir(origDir)
  buildCompilerSecond(tmpDir, "nim_pgo", profs)
  #removeDir(tmpDir) # remove all the temp stuff
  delEnv("NIMBLE_DIR") # so you can use nimble normally after you'r done


main()