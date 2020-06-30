#[
  See https://forum.nim-lang.org/t/4621
  Just a really simple logging module :)
]#
import std / [
  macros, terminal, strutils, strformat, times
]

type
  LogLevel* = enum
    lvlDebug = "DEBUG"
    lvlInfo = "INFO"
    lvlNotice = "NOTICE"
    lvlWarn = "WARN"
    lvlError = "ERROR"
    lvlFatal = "FATAL"

# Default logging level, can be changed
var logLevel* = lvlInfo
# Do we want to use colors for the log?
var useColors* = true

const levelToColor: array[LogLevel, ForegroundColor] = [
  fgWhite, fgGreen, fgCyan, fgYellow, fgRed, fgRed
]

proc log*(lvl: LogLevel, line: string) =
  ## Logs message with specified log level to the stdout
  if useColors:
    setForegroundColor(stdout, levelToColor[lvl])
  echo fmt"{now()} |{$lvl:^#8}| {line}"
  if useColors:
    resetAttributes()

macro getFormatted(data: varargs[untyped]): untyped =
  ## Returns a strutils.format call for code like
  ## getFormatted("Test", a = 1, b = "hello")
  result = newTree(nnkCall)
  result.add bindSym"format"

  var fmtString = ""
  var i = 1
  # List of arguments to a `format` call
  var tmp = newSeq[NimNode]()

  for arg in data:
    if i > 1: fmtString &= ", "
    # Literal string
    if arg.kind == nnkStrLit:
      fmtString &= arg.strVal
    # a = b
    elif arg.kind == nnkExprEqExpr:
      fmtString &= arg[0].strVal & " = $" & $i
      tmp.add(arg[1])
      inc(i)
  
  result.add(newLit(fmtString))
  # Add nodes which will be used as arguments
  for node in tmp:
    result.add(node)
  echo repr result

template genTemplate(name: untyped, lvl: untyped): untyped =
  template name*(data: varargs[untyped]): untyped =
    log(lvl, getFormatted(data))

# Generate templates for all log levels
genTemplate(logDebug, lvlDebug)
genTemplate(logInfo, lvlInfo)
genTemplate(logNotice, lvlNotice)
genTemplate(logWarn, lvlWarn)
genTemplate(logError, lvlError)
genTemplate(logFatal, lvlFatal)

template fatalError*(data: varargs[untyped]) =
  logFatal(data)
  quit()

when isMainModule:
  logNotice("starting up!")
  logInfo("starting ok!")
  logInfo(data = "something", i = 1, isWorldBurning = true)
  logWarn("something is not okay")
  logError("wow, an error!")
  fatalError("shutting down")
