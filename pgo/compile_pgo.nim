# bad code ahead, you've been warned!
import std/[os, osproc, strutils, strformat, tempfiles]

type
  CompileEntry = tuple
    url, file: string
    nimble, orc: bool

const 
  IsOrcDefault = true
  IsGcc = false

# repo to clone, nim file to compile, install nimble deps, test with orc (not really relevant anymore)
const ToCompile: seq[CompileEntry] = @[
  ("https://github.com/mratsim/Arraymancer", "tests/tests_cpu.nim", true, true),
  ("https://github.com/zevv/npeg", "tests/tests.nim", true, true),
  ("https://github.com/planety/prologue", "examples/todoapp/app.nim", true, true),
  ("https://github.com/zedeus/nitter", "src/nitter.nim", true, true),
  ("https://github.com/rlipsc/polymorph", "tests/testall.nim", true, true),
  ("https://github.com/nim-lang/nim-regex", "tests/tests.nim", true, true),
  ("https://github.com/nim-lang/nim", "compiler/nim.nim", false, true)
]
#[
  My criteria for adding repos:
    Arraymancer - a lot of generics, concepts, etc
    Npeg - a lot of compile-time macros code
    Prologue - a lot of async, popular framework
    Nitter - also a lot of async
    Polymorph - a lot of macro code
    Nim-regex - really really heavy for the VM macro code
    Nim - the compiler itself 
]#


var 
  i = 1

proc profileName(tmpDir: string, name: string) =
  let val = 
    if IsGcc:
      tmpDir / "profiles" / (name & $i)
    else:
      tmpDir / "profiles" / (name & $i & ".profraw")
  putEnv(if IsGcc: "GCCPROF" else: "LLVM_PROFILE_FILE", val)
  inc i

proc compilePgo(compBin, tmpDir, name, filePath: string, orc: bool) = 
  # We also compile without danger so that the paths related
  # to debug code (assertions, safety checks, stack traces, etc) also get optimized
  let nimbleDir = tmpDir / "nimble/"
  let commonArgs = fmt"c --clearNimblePath --verbosity:0 -h:off -w:off --NimblePath:{nimbleDir}/pkgs/ --NimblePath:{nimbleDir}/pkgs2/ -f --compileOnly"
  profileName(tmpDir, name)
  doAssert execCmd(fmt"{compBin} {commonArgs} {filePath}") == 0
  profileName(tmpDir, name)
  doAssert execCmd(fmt"{compBin} {commonArgs} -d:danger {filePath}") == 0
  if orc and not IsOrcDefault:
    profileName(tmpDir, name)
    doAssert execCmd(fmt"{compBin} {commonArgs} --mm:orc {filePath}") == 0
    profileName(tmpDir, name)
    doAssert execCmd(fmt"{compBin} {commonArgs} --mm:orc -d:danger {filePath}") == 0


proc buildCompilerFirst(tmpDir, binName: string): string = 
  let
    CommonArgs = @[
      "c", "-d:danger", 
      "--cc:" & (if IsGcc: "gcc" else: "clang"), 
      "--verbosity:0",
      "--passC:-flto", "--passL:-flto",
      "-o:bin/" & binName, 
    ]
  let args = CommonArgs & (
    if IsGcc:
      @[
        fmt"--passC:-fprofile-generate=%q{{GCCPROF}}", 
        fmt"--passL:-fprofile-generate=%q{{GCCPROF}}"
      ]
    else:  
      @[
        "--passC:-fprofile-instr-generate", 
        "--passL:-fprofile-instr-generate",
      ]
  ) & @["compiler/nim.nim"]

  doAssert execCmd("nim " & args.join(" ")) == 0
  result = expandFilename("bin/" & binName)

proc buildCompilerSecond(tmpDir, binName: string, profs: seq[string]) =   
  let args = 
    if IsGcc:
      @[
        "c", "-d:danger", "--cc:gcc",
        fmt"--passC:-fprofile-use={tmpDir}/profiles/main --passC:-fprofile-correction", 
        fmt"--passL:-fprofile-use={tmpDir}/profiles/main --passL:-fprofile-correction",
        "--passC:-flto", "--passL:-flto",
        "-o:bin/" & binName, "compiler/nim.nim"
      ]
    # clang
    else:
      @[
        "c", "-d:danger", "--cc:clang",
        fmt"--passC:-fprofile-instr-use={tmpDir}/main.profdata", 
        fmt"--passL:-fprofile-instr-use={tmpDir}/main.profdata",
        "--passC:-flto", "--passL:-flto",
        "-o:bin/" & binName, "compiler/nim.nim"
      ]

  doAssert execCmd("nim " & args.join(" ")) == 0

proc main = 
  # build stage 1 pgo compiler
  let origDir = getCurrentDir()
  let tmpDir = createTempDir("nim_pgo", "")
  echo "Created temp dir: ", tmpDir
  echo "Building stage 1 compiler (may take a while due to LTO)"
  let path1 = buildCompilerFirst(tmpDir, "nim_temp_pgo")
  setCurrentDir(tmpDir)

  echo "Stage 1 compiler built"

  # so we don't pollute the default nimble dir
  putEnv("NIMBLE_DIR", tmpDir / "nimble")
  # compile and generate profiles for all projects
  for entry in ToCompile:
    echo "Compiling ", entry.url
    let entryName = entry.url.split("/")[^1]
    # depth=1 so no history
    doAssert execCmd(fmt"git clone --quiet --depth=1 {entry.url}") == 0
    setCurrentDir(entryName)
    # if the project has nimble deps, install them
    if entry.nimble:
      echo "Installing Nimble deps..."
      # TODO: Add --silent when the script is stable enough
      # -y - no confirmation, -d - only deps, don't build the project itself (since we do it manually)
      doAssert execCmd(fmt"nimble install -y -d --silent") == 0
    compilePgo(path1, tmpDir, entryName, entry.file, entry.orc)
    setCurrentDir("..")
    echo "Done profiling the compiler for ", entry.url
    
  # find names for all the generated profiles
  var profs: seq[string]
  if IsGcc:
    # I have no idea how to fix GCC putting files into /tmp/folder/profiles/folder/profiles
    # instead of /tmp/folder/profiles
    echo tmpDir / "profiles"
    for pc in walkDir(tmpDir / "profiles"):
      if pc.kind == pcDir:
        profs.add pc.path

    # Not sure if this is correct, but we basically make the first profile "main"
    # and then merge all the other profiles into it
    copyDir(profs[0], tmpDir / "profiles" / "main")

    for prof in profs[1..^1]:
      let cmd = fmt"gcov-tool merge {prof} {tmpDir}/profiles/main --output {tmpDir}/profiles/main" 
      doAssert execCmd(cmd) == 0
  else:
    for pc in walkDir(tmpDir / "profiles"):
      if pc.kind == pcFile and pc.path.endsWith(".profraw"):
        profs.add pc.path
    let profsStr = profs.join(" ")
    doAssert execCmd(fmt"llvm-profdata merge {profsStr} -output {tmpDir}/main.profdata") == 0
  echo fmt"Merged {profs.len} profiles"
  echo "Building the final stage-2 compiler with PGO"
  
  # build stage 2 pgo compiler
  setCurrentDir(origDir)
  buildCompilerSecond(tmpDir, "nim_pgo_clang", profs)
  removeDir(tmpDir) # remove all the temp stuff
  delEnv("NIMBLE_DIR") # so you can use nimble normally after you'r done


main()