# Finding all Nim files that use term-rewriting macros:

```re
^\s*(template|macro)\s*[^`\s{(]*\{[^}]*\}
```

Files to include: `./pkgraph/repos/`

Files to exclude: `*.md, *.txt, ./pkgraph/repos/nim/tests`

40 results in 18 files (09/10/22)

# AST overloading

```re
(proc|iterator|macro|template|func|method|converter)[^(]*\([^{]*:\s*[^\s,=\{]*\{(atom|lit|sym|ident|call|lvalue|sideeffect|nosideeffect|param|genericparam|module|type|var|let|const|result|proc|method|iterator|converter|macro|template|field|enumfield|forvar|label|nk[a-zA-Z]*|alias|noalias)*\}
```

`./pkgraph/repos/**/*.nim`

`*.md, *.txt, ./pkgraph/repos/nim/tests`

106 results in 58 files (09/10/22), but also some false positives (and maybe some missing results)