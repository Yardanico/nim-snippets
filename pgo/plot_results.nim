import std/[json, strutils, strformat, sequtils, algorithm, strscans, tables, math]
import pkg/[nimib, plotly, chroma]

import ./common

nbInit

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

proc plotResults(filename: string): Plot[float] = 
  var results = getBenchStats(parseFile filename)  
  # Sort by time
  results = results.sortedByIt(it.time)
  # Round the results to 2 decimal places
  for res in results.mitems:
    res.time = res.time.round(2)

  let baseline = results[0].time

  var yAxis = Axis(title: "Compile time (s)")
  # Set the baseline as 0.9 of the lowest value, highest - 1.1 of the highest value
  yAxis.range = (baseline * 0.9, results[^1].time * 1.1)

  var traces = @[
    Trace[float](name: "GCC", `type`: PlotType.Bar, opacity: 0.6, marker: Marker[float](color: @[parseHex("FFA500")])),
    Trace[float](name: "Clang", `type`: PlotType.Bar, opacity: 0.6, marker: Marker[float](color: @[parseHex("005500")]))
  ]

  # Add our actual data and text
  for res in results:
    traces[int res.compiler].ys.add res.time
    traces[int res.compiler].text.add res.text
  
  # HoverMode.X = Compare data on hover
  let layout = Layout(title: "Nimble", yaxis: yAxis, autosize: true, hoverMode: HoverMode.X)
  result = Plot[float](layout: layout, traces: traces)

nbText:
  """
  The plots from here show Nim compilation speed of some projects. The compilation time *only* 
  includes Nim compilation time itself (including the creation of C files), but does not include the C
  compilation speed. Lower is better.
  """

nbPlotly(plot):
  let plot = plotResults("results/nimble.json")

nbSave