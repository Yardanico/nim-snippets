#[
An (almost) direct translation of a https://esolangs.org/wiki/Pyhton_(sic)
interpreter from the original https://github.com/SomethingFawful/pyhton
implementation.

Notable changes include:
- No global state, there's an Interpreter object
- Arrays for AT* lookup tables instead of dicts
- Case statement for the character table instead of a dict
- Arrays for opcode proc lookups instead of dicts

TODO:
- Debugging output

This code wasn't tested thoroughly as there's almost no
pyhton [sic] examples available. 

]#

import std/[math, strutils, parseopt]

type
  Septit = object
    value: int
  
  Register = object
    regs: array[7, Septit]
  
  Interpreter = object
    ip: int # Instruction pointer
    ipLen: int # base-7 length of instruction pointer
    r: Register # Interpreter registers
    p: seq[Septit] # Actual program code
    outWidth: int
    isDebug: bool

const
  # AcTion A table
  Ata = [3, 1, 2, 6, 5, 6, 0]
  # AcTion B table
  Atb = [2, 3, 6, 5, 1, 0, 4]
  # AcTion C table
  Atc = [6, 2, 3, 1, 5, 0, 4]

template dbgPrint(str: string): untyped = 
  if ir.isDebug:
    stdout.write(str)

proc initSeptit(value: int): Septit = 
  Septit(value: value.floorMod(7))

proc ata(s: var Septit) = 
  s.value = Ata[s.value]

proc atb(s: var Septit) = 
  s.value = Atb[s.value]

proc atc(s: var Septit) = 
  s.value = Atc[s.value]

proc ata(s: var Register, idx: int) = 
  s.regs[idx].ata()

proc atb(s: var Register, idx: int) = 
  s.regs[idx].atb()

proc atc(s: var Register, idx: int) = 
  s.regs[idx].atc()

proc toInt(s: Register): int = 
  for sep in s.regs:
    result = result * 7 + sep.value

proc update(s: var Register, val: int) = 
  var val = val
  for i in countdown(6, 0):
    s.regs[i] = initSeptit(val.floorMod(7))
    val = val.floorDiv(7)

proc convert(c: char): int = 
  case c
  of ']': 0
  of '#': 1
  of '+': 2
  of '^': 3
  of ';': 4
  of '{': 5
  of ':': 6
  of ')': 7
  of '<': 8
  of ',': 9
  of '6': 10
  of '\t': 11
  of 'h': 12
  of '\'': 13
  of '(': 14
  of '5': 15
  of '>': 16
  of '@': 17
  of '0': 18
  of '?': 19
  of 'I': 20
  of '9': 21
  of '3': 22
  of '1': 23
  of '/': 24
  of '7': 25
  of '.': 26
  of ' ': 27
  of 'i': 28
  of 'l': 29
  of '|': 30
  of '!': 31
  of '~': 32
  of '8': 33
  of '-': 34
  of '=': 35
  of '$': 36
  of '[': 37
  of '4': 38
  of '&': 39
  of '}': 40
  of '`': 41
  of '_': 42
  of '*': 43
  of '"': 44
  of '\\': 45
  of '2': 46
  of '%': 47
  of '\n': 48
  else: raise newException(ValueError, "Unknown character!")

proc getIpLen(len: int): int = 
  var len = len
  while len > 0:
    inc result
    len = len.floorDiv(7)

proc initInterpreter(data: string, isDebug = false): Interpreter =
  result = Interpreter(outWidth: -1, isDebug: isDebug)
  for c in data:
    let tmp = convert(c)
    result.p.add initSeptit(tmp.floorDiv(7))
    result.p.add initSeptit(tmp.floorMod(7))
  result.ipLen = getIpLen(len(result.p))

using
  ir: var Interpreter

proc nop(ir) = 
  ## No operation, your standard NOP command.
  inc ir.ip

proc ata(ir) = 
  ## AcTion A. Adjust the value of the register given in the next Septit 
  ## of the program, it will convert a register according to the Ata table
  ir.r.ata(ir.p[ir.ip + 1].value)
  ir.ip += 2

proc atb(ir) = 
  ## AcTion A. Adjust the value of the register given in the next Septit 
  ## of the program, it will convert a register according to the Atb table
  ir.r.atb(ir.p[ir.ip + 1].value)
  ir.ip += 2

proc atc(ir) = 
  ## AcTion A. Adjust the value of the register given in the next Septit 
  ## of the program, it will convert a register according to the Atc table
  ir.r.atc(ir.p[ir.ip + 1].value)
  ir.ip += 2

proc rdi(ir) = 
  ## ReaD Input. Reads 7 septits of input into the register. 
  ## What exactly the input is can be implementation dependent, as it is 
  ## not part of the spec. In the standard implementation, it reads an integer 
  ## from Standard Input, and converts it into 7 septits, ignoring any extra, 
  ## with the 6th septit being the least significant.
  ir.r.update(parseInt(stdin.readLine()))
  inc ir.ip

proc wrt(ir) = 
  ## WRiTe. Writes the content of the 7 septits to memory, with the zeroth
  ## septit in the register being at the location given after the 41.
  ## The index value of where to write is absolute, and dependant on the
  ## length of the program. Should the value be above the length of the 
  ## program, it will expand the program, padded with 0s, but will not increase
  ## the program's index size. For example if the current index size is 3
  ## (so the program is less than 343 Septits long), 41665 will increase
  ## the programs size to be exactly 343 septits long, but no more.
  var wp = 0
  var ipLen = getIpLen(len(ir.p))
  for i in 0 ..< ipLen:
    inc ir.ip
    wp *= 7
    wp += ir.p[ir.ip].value
  
  while wp >= len(ir.p):
    ir.p.add Septit()
  
  for reg in ir.r.regs:
    if wp == len(ir.p):
      if getIpLen(wp) > iPLen:
        return
      else:
        ir.p.add(initSeptit(reg.value))
    else:
      ir.p[wp] = initSeptit(reg.value)
    inc wp
  
  inc ir.ip

proc `out`(ir) = 
  ## OUTput. Outputs the values stored at the beginning of the program.
  ## How exactly it is output can be implementation dependent,
  ## is it is not part of the spec. In the standard implementation,
  ## it is converted 3 septits to a Unicode character between 0 and 343,
  ## which is output to Standard Output. How many septits it will output
  ## is dependent on the value set by the AOS command, and using
  ## OUT before AOS will crash in a compliant implementation.
  var 
    outted = 0
    outvals = 0
  
  for i in 0 ..< ir.outWidth:
    inc outted
    outvals *= 7
    outvals += ir.p[i].value

    if outted == 3:
      outted = 0
      stdout.write(chr(outvals))
      outvals = 0
  
  inc ir.ip

proc plp(ir) = 
  ## PLoP. Increases the size of the program by 1 septit.
  ## Unlike WRT, PLP Will increase the size of the index if neccessary.
  ## This allows for infinite memory in a fully complaint implementation.
  ir.p.add Septit()
  ir.ipLen = getIpLen(len(ir.p))
  
  inc ir.ip

proc aos(ir) = 
  ## Adjust Output Size. Adjusts the amount of the start of the program
  ## that will be output. Uses the values in the register, with the 0th
  ## septit being the most significant.
  ir.outWidth = ir.r.toInt()
  inc ir.ip

proc `end`(ir) = 
  ## END program. Using END is the only way to correctly end a program.
  ## Should a compliant implementation reach the end of memory without
  ## encountering END it should crash.
  quit()

proc slp(ir) = 
  ## SLeeP. Similar to the SLP opcode in 65c816 Assembly. 
  ## Causes the program to perminantly enter an infinite loop.
  while true:
    discard

proc jmp(ir) = 
  ## JuMP. Unconditional Jump to the specified location.
  ## As with WRT the address is absolute and size of address
  ## depends on the length of the program.
  var newIp = 0
  
  for i in 0 ..< ir.ipLen:
    inc ir.ip
    newIp *= 7
    newIp += ir.p[ir.ip].value
  
  ir.ip = newIp

var OpCode: array[7, proc (ir: var Interpreter) {.nimcall.}] = [
  nop, ata, atb, atc, nil, slp, jmp
]

var OpCode4: array[7, proc (ir: var Interpreter) {.nimcall.}] = [
  rdi, wrt, `out`, plp, aos, `end`, nil
]

proc op4(ir) = 
  inc ir.ip
  OpCode4[ir.p[ir.ip].value](ir)

OpCode[4] = op4

proc rnr(ir) = 
  ## RuN Register. Runs through the register as if it was 
  ## the next 7 Septitsof the program. This is currently untested 
  ## and glitchy in the official implementation.
  inc ir.ip

  OpCode[ir.r.regs[ir.p[ir.ip + 1].value].value](ir)
  
  inc ir.ip

OpCode4[6] = rnr

proc run(ir: var Interpreter) = 
  while true:
    OpCode[ir.p[ir.ip].value](ir)

proc main = 
  var p = initOptParser()
  var isDebug = false
  var fname: string
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.key == "debug": isDebug = true
    of cmdArgument:
      fname = p.key
  if fname == "":
    quit("Usage: ./pyhton file.py or ./pyhton --debug file.py to enable debugging.")

  var ir = initInterpreter(readFile(fname), isDebug)
  ir.run()


main()