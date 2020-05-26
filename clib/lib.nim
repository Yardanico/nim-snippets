# nim c -d:danger --gc:arc --app:lib --out:lib.so lib.nim
import mathexpr

{.push exportc, dynlib.}

proc new_evaluator(): pointer =
  let e = mathexpr.newEvaluator()
  # Increase refcount for the evaluator object
  # so that it doesn't get destroyed when it gets out of the scope
  # of this procedure
  GC_ref(e)
  result = cast[pointer](e)

proc eval(e: pointer, data: cstring, code: ptr cint): cdouble =
  # We need to initialize the code variable since it's not initialized on the
  # C side implicitly
  code[] = 0
  let e = cast[Evaluator](e)
  try:
    result = e.eval($data)
  except:
    code[] = 1

proc free_evaluator(e: pointer) =
  # Decrease refcount for the evaluator object so it will be destroyed
  # after this procedure
  GC_unref(cast[Evaluator](e))