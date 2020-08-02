#!/bin/bash
# This is a simple script to compile the Nim compiler with
# PGO (no LTO because as of now, if used with PGO, it breaks the compiler)
# Use Arraymancer, npeg and compiler to provide data for PGO
git clone --depth 1 https://github.com/mratsim/Arraymancer
cd Arraymancer
nimble install
cd ..
git clone --depth 1 https://github.com/zevv/npeg
cd npeg
nimble install
cd ..
# Compile the profiling version to generate PGO data
nim c -d:danger --cc:clang --passC:"-fprofile-instr-generate" --passL:"-fprofile-instr-generate" \
-o:bin/nimpgo1 compiler/nim.nim
# Gather data from Arraymancer compilation
./bin/nimpgo1 c -d:danger Arraymancer/tests/tests_cpu.nim
mv default.profraw arraymancer.profraw
# Gather data from npeg compilation
./bin/nimpgo1 c -d:danger npeg/tests/tests.nim
mv default.profraw npeg1.profraw
# npeg + arc for ARC/ORC compiler analysis stuff
./bin/nimpgo1 c -d:danger --gc:orc npeg/tests/tests.nim
mv default.profraw npeg2.profraw
# Gather data from compiler compilation
./bin/nimpgo1 c -d:danger -o:tempcompbin compiler/nim.nim
mv default.profraw compiler1.profraw
# compiler compiled with ARC (for analysis stuff)
./bin/nimpgo1 c -d:danger -o:tempcompbin --gc:arc -d:leanCompiler compiler/nim.nim
rm tempcompbin
mv default.profraw compiler2.profraw
llvm-profdata merge arraymancer.profraw npeg1.profraw npeg2.profraw compiler1.profraw \
compiler2.profraw -output data.profdata
# Compile the compiler with PGO
nim c -d:danger --cc:clang --passC:"-fprofile-instr-use=data.profdata" \
--passL:"-fprofile-instr-use=data.profdata" -o:bin/nim compiler/nim.nim
