import std / [
  db_sqlite, strutils, times, math, tables, strformat
]

type
  Day = ref object
    irc: int
    disc: int
    gitter: int
    matrix: int

proc freq(db: DbConn) = 
  var tbl = initOrderedTable[string, Day]()

  for row in db.fastRows(sql"select timestamp, service from log"):
    let t = fromUnix(parseInt(row[0])).format("YYYY-MM-dd")
    var entry = tbl.mgetOrPut(t, Day())

    case row[1]
    of "IRC": inc entry.irc
    of "Matrix": inc entry.matrix
    of "Discord": inc entry.disc
    of "Gitter": inc entry.gitter
    else: discard # can't happen
  
  var f = open("freq.csv", fmWrite)
  for dt, day in tbl:
    f.writeLine(fmt"{dt},{day.irc},{day.disc},{day.gitter},{day.matrix}")
  f.close()

proc user(db: DbConn) = 
  var tbl = initCountTable[string]()

  # select author from log
  for row in db.fastRows(sql"select author, timestamp from log where timestamp > 1581406660"):
    tbl.inc(row[0])
  
  tbl.sort()

  var f = open("user_msg_last_year.csv", fmWrite)
  f.writeLine("username,count")
  for user, cnt in tbl:
    f.writeLine(fmt"{user},{cnt}")
  
  f.close()

proc main = 
  let db = open("irc.db", "", "", "")

  when false:
    freq(db)
  when true:
    user(db)

  db.close()

main()