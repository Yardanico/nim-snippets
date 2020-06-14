import macros

macro unpack*(data: untyped, values: varargs[untyped]): untyped = 
  runnableExamples:
    # Simple unpacking - you need to provide the length to unpack
    let (a, b, c) = @[1, 2, 3, 4].unpack(3)
    doAssert (a + b + c) == 6

    doAssert @[1, 2, 3, 5].unpack(2) == (1, 2)

    # You can call unpack with variable names so you don't have to provide
    # the length to unpack
    # You can also optionally use `_` for values you don't want to get
    @[1, 2, 3, 5, 6].unpack(g, x, _, _, z)

    # You're not limited to simple expressions, you can call this
    # macro with somewhat complex expressions or variables
    let values = @[3, 2, 5, 7]
    doAssert values.unpack(4) == (3, 2, 5, 7)

    import strutils
    "how are you".split().unpack(ca, cb, cc)

    doAssert @[ca, cb, cc].join(", ") == "how, are, you"
  
  let lenPresent = values.len == 1 and values[0].kind == nnkIntLit
  let nameIdent = genSym(nskLet, "data")
  
  result = nnkStmtList.newTree()

  result.add quote do:
    let `nameIdent` = `data`

  if lenPresent:
    var data = nnkPar.newTree()

    for ind in 0 ..< values[0].intVal:
      data.add quote do:
        `nameIdent`[`ind`]
    
    result.add data
  
  else:
    for ind in 0 ..< values.len:
      let val = values[ind]
      # _ usually means "we don't want that value"
      if val == ident"_": continue

      result.add quote do:
        let `val` = `nameIdent`[`ind`]

when isMainModule:
  block:
    let data = @[1, 2, 3, 4]
    let (a, b, c) = data.unpack(3)
    doAssert (a + b + c) == 6

  block:
    let data = "hello"
    let (a, b, c) = data.unpack(3)
    doAssert (a & b & c) == "hel" 
  
  block:
    let data = @[1, 2, 3, 4, 5, 6]
    data.unpack(a, b, c, _, _, g)
    doAssert (a + b + c + g) == 12
  
  echo "Tests passed successfully!"