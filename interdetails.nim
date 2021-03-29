## Some (maybe) useful templates/procs to get implementation
## specific info, like refcount or capacity for strings/seqs

const isRefc = compileOption("gc", "refc")
const isArc = compileOption("gc", "arc")
const isOrc = compileOption("gc", "orc")
const isArcOrc = isArc or isOrc

when isRefc:
  # https://github.com/nim-lang/Nim/blob/devel/lib/system/gc.nim#L183
  proc internRefcount(p: pointer): int {.importc: "getRefcount".}

elif isArcOrc:
  type
    RefHeader = object
      rc: int
      # Either rootIdx for ORC or PNimType for refc
      when isOrc or isRefc:
        rootIdx: int
    
    Cell = ptr RefHeader
  
  const rcShift = 3

  template head(p: pointer): Cell =
    cast[Cell](cast[int](p) -% sizeof(RefHeader))

  template internRefcount(p: pointer): int = 
    head(p).rc shr rcShift

template getRc*[T](p: T): int =
  ## Get the reference count of a variable `p`.
  ## 
  ## .. warning:: **Extremely unsafe!**
  when p is string: {.error: "Can't get the refcount of a string".}
  elif p is seq: {.error: "Can't get the refcount of a seq".} 
  internRefcount(cast[pointer](p))

when isArcOrc or defined(nimdoc):
  type
    SeqData = object
      cap: int
    
    SeqHeader = object
      len: int
      data: ptr SeqData
  
  template getCap*(x: seq | string): int = 
    ## Get capacity of a sequence `x`.
    ## 
    ## .. warning:: Unsafe!
    cast[SeqHeader](x).data[].cap

elif isRefc:
  type
    SeqHeader = object
      len, cap: int
  
  template getCap*(x: seq | string): int =
    ## Get capacity of a sequence `x`.
    ## 
    ## .. warning:: Unsafe!
    cast[ptr SeqHeader](x).cap

