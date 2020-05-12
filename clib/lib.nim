# nim c -d:danger --gc:arc --app:lib --debugger:native --out:lib.so lib.nim
import mathexpr

proc new_evaluator(): pointer {.exportc, dynlib.} = 
  let e = mathexpr.newEvaluator()
  GC_ref(e)
  result = cast[pointer](e)

proc eval(e: pointer, data: cstring, code: var cint): cdouble {.exportc, dynlib.} =
  let e = cast[Evaluator](e)
  result = e.eval($data)

proc free_evaluator(e: pointer) {.exportc, dynlib.} = 
  GC_unref(cast[Evaluator](e))