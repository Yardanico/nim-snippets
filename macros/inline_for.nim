# A really simple inline for loop implementation
import std/macros

macro makeLoop(expr: untyped, vals: typed, valsLen: static[int], body: untyped): untyped = 
  result = newStmtList()
  # For each value we add the template with the name of the
  # for loop variable. This works because each new template
  # will overwrite the older one
  for i in 0 ..< valsLen:
    result.add quote do:
      template `expr`(): untyped = `vals`[`i`]
      `body`
  
  echo repr result

macro inlineFor(x: ForLoopStmt): untyped = 
  expectKind x, nnkForStmt
  let expr = x[0]
  let call = x[1][1]
  let body = x[2]

  var vals = gensym(nskConst, "vals")
  var data = gensym(nskVar, "data")
  
  # We evaluate the expression and get all of its values in a
  # const-time seq `vals`, and then call makeLoop
  result = quote do:
    const `vals` = static:
      var `data`: seq[typeof(items(`call`))]
      for x in `call`:
        `data`.add(x)
      `data`
    
    makeLoop(`expr`, `vals`, `vals`.len):
      `body`

proc main = 
  var res = 0
  
  for f in inlineFor([0, 1, 2]):
    res += f

  echo res

main()
