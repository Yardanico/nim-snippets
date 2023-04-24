import std/[json, strutils, strformat, sequtils, algorithm, strscans, tables, math]
import pkg/[nimib, plotly, chroma]

import ./common

nbInit

# nb.darkMode - no clue how to make plotly dark

# https://pietroppeter.github.io/nblog/drafts/show_plotly.html
template usePlotly(doc: var NbDoc) =
  import plotly / [api, plotly_types, plotly_display]
  # I should create a doc.addToHead proc for this:
  doc.partials["head"] &= """<script src="https://cdn.plot.ly/plotly-latest.min.js"></script>"""
  doc.partials["nbPlotly"] = """
<div id="{{plot_id}}"></div>
<script>
  Plotly.newPlot('{{plot_id}}', {{&plot_data}}, {{&plot_layout}});
</script>
"""
nb.usePlotly

template nbPlotly(plot, body: untyped) =
  ## plot must be the identifier of Plotly's plot in body
  newNbCodeBlock("nbPlotly", body):
    body

    nb.blk.context["plot_id"] = "plot-" & $nb.newid
    nb.blk.context["plot_data"] = block:
      when type(plot) is Plot:
        parseTraces(plot.traces)
      else:
        $plot.traces

    nb.blk.context["plot_layout"] = block:
      if plot.layout != nil:
        when type(plot) is Plot:
          $(%plot.layout)
        else:
          $plot.layout
      else:
        "{}"

type
  HyperfineParams = object
    compiler: string
  HyperfineResult = object
    mean: float
    min: float
    max: float
    parameters: HyperfineParams
  BenchmarkResult = object
    compiler: Compiler
    time: float
    text: string

proc getBenchStats(data: JsonNode): seq[BenchmarkResult] =
  let data = data["results"].to(seq[HyperfineResult])
  for run in data:
    let (_, compStr, compFlags) = run.parameters.compiler.scanTuple("nim_$+_$+")
    let compiler = parseEnum[Compiler](compStr)
    # don't look here
    let text = compFlags.multiReplace(
      {"_": " ", "dan": "Danger", "rel": "Release", "lto": "(LTO)", "pgo": "Danger (LTO, PGO)"}
    )
    
    result.add BenchmarkResult(compiler: compiler, time: run.mean, text: text)

proc plotResults(filename, graphName: string): Plot[float] = 
  var results = getBenchStats(parseFile filename)  
  # Sort by time
  results = results.sortedByIt(it.time)
  # Round the results to 2 decimal places
  for res in results.mitems:
    res.time = res.time.round(2)

  #let baseline = 1.0 #results[0].time

  var yAxis = Axis(title: "Compile time (s)")
  # Set the baseline as 0.9 of the lowest value, highest - 1.1 of the highest value
  #yAxis.range = (baseline * 0.9, results[^1].time * 1.1)

  # Colors chosen by Mr. Beef
  var traces = @[
    Trace[float](name: "GCC", `type`: PlotType.Bar, opacity: 1, marker: Marker[float](color: @[parseHex("B5651D")])),
    Trace[float](name: "Clang", `type`: PlotType.Bar, opacity: 1, marker: Marker[float](color: @[parseHex("C0C0C0")]))
  ]

  # Add our actual data and text
  for res in results:
    traces[int res.compiler].ys.add res.time
    traces[int res.compiler].text.add res.text
  
  # HoverMode.X = Compare data on hover
  let layout = Layout(
    title: graphName, yaxis: yAxis, 
    autosize: true, hoverMode: HoverMode.X, showLegend: true, legend: Legend(orientation: Orientation.Horizontal, x: 0, y: 1)
  )
  result = Plot[float](layout: layout, traces: traces)

nbText:
  """
  This page contains graphs that show compilation speed (in seconds) for some Nim projects.
  The compilation time *only*  includes Nim compilation time itself (including the creation of C files),
  but does not include the C compilation speed. Lower is better.

  Projects used for generating PGO profile data:
  - Arraymancer
  - NPeg
  - Prologue
  - Nitter
  - Polymorph
  - regex
  - Nim compiler
  
  I chose some of these projects because they heavily use compile-time Nim execution or macros, 
  some - because they use async (heavy on the static analysis done for ARC/ORC), 
  and some - just because they need to be there.

  All projects were compiled with ORC in debug (to also optimize for debugging features) and release modes.

  Tests were done on my Arrch Linux machine (Ryzen 3700X, NVMe SSD) with GCC 12.2.1 and Clang 15.0.7.

  The benchmark data was collected using Hyperfine. 
  Each option was benchmarked 3 times (low, I know) because I didn't want to wait too long for results.

  This page was done using [nimib](https://github.com/pietroppeter/nimib) (the best out there!), 
  plots were done with [nim-plotly](https://github.com/SciNim/nim-plotly/).

  Source code for all relevant files can be found in the
  [pgo folder](https://github.com/Yardanico/nim-snippets/tree/master/pgo) of my snippets repo.
  """

#[
nbPlotly(pltNimble):
  let pltNimble = plotResults("results/nimble.json", "Nimble")

nbText:
  """
  Nimble. Really fast to compile, even if PGO here is much faster, it's not much difference.
  """
]#

nbPlotly(pltNim):
  let pltNim = plotResults("results/compiler.json", "Nim")

nbText:
  """
  The compiler itself. PGO speedup here is quite significant (**1.7x** over normal release).
  And we can already see that Clang is consistently faster than GCC if the compilation involves LTO or PGO ;)
  """

nbText:
  """
  Now, how about we test it on some projects that were in the PGO training data?
  """

nbPlotly(pltArraymancer):
  let pltArraymancer = plotResults("results/arraymancer.json", "Arraymancer")

nbText:
  """
  Clang PGO again comes out on top.
  """

nbPlotly(pltMoe):
  let pltMoe = plotResults("results/moe.json", "Moe")

nbText:
  """
  A text editor made in Nim that has a very cute name ^_^. And at this point it's clear - the results
  for different projects are all mostly *consistent* to each other regarding how fast is a specific combination
  to another one. Yes, some projects compile faster, but the actual percentage difference 
  between versions is the same ¯\_(ツ)_/¯.
  """

nbPlotly(pltOwlkettle):
  let pltOwlkettle = plotResults("results/owlkettle_todo.json", "Owlkettle (TODO app)")

nbText:
  """
  I was really surprised by Owlkettle being so fast! This is not compiling all of Owklettle, just the TODO app.
  With PGO you get 0.5 seconds for the Nim part, although the C compilation takes an additional 3.3 seconds (without C cache).
  If it wasn't already evident - PGO'd Nim compiler is only good for big Nim projects. The smaller the project,
  the less of a difference you'll see.
  """

nbPlotly(pltRegex):
  let pltRegex = plotResults("results/regex.json", "regex (Nimble)")

nbText:
  """
  regex is a pure-Nim regex library, which means you can both pre-compile and use regexes at compile-time.
  It's quite VM heavy, and the test file for it takes a really really long time to compile, 
  because it has tons of different regexes that are all tested on both runtime and compile-time.
  The results are indeed quite significant - seems like the Nim VM was heavily optimized by PGO. 
  I think it won't hurt to use a PGO'd compiler if you use nim-regex in your Nim project a lot :)
  """

nbText:
  """
  # Conclusion
  This was a fun experiment, although the graphs were a bit too boring - the scaling is similar in all of them.
  
  It's just another confirmation that Nim programs do benefit from LTO and PGO (see e.g. [my old forum post](https://forum.nim-lang.org/t/6295)).
  However, the difference for the compiler is not that big, 
  especially when compiling smaller Nim libraries/projects. 
  
  Judging by those results,  you should look at how long a typical compilation of your project 
  takes with `--compileOnly`, divide than by 1.7, and see if that time decrease
  will be significant enough for you, considering the C compilation time. 
  Though do not forget that when developing your project you'll be re-using
  most of the C files, so the C compilation time will be quite low enough to make Nim compilation time noticeable,
  unless your project takes
  a significant time to link.
  
  Also, PGO for the compiler will (mostly) become obsolete when Nim gets incremental compilation, which I believe is on the roadmap for 2023.

  P.S.: If your Nim project does some heavy data processing,
  it won't hurt to try doing PGO on it,
  and as for LTO - you should generally always use it for release builds
  unless it slows your program down or results in some bugs.

  Thanks for reading this not particularly useful post.
  """

nbSave