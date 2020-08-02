#[
  Parser for IRC log entries of NimBot.
  Assumes you have all the .logs and .html files in the "irclogs"
  directly (can be tweaked).

  Uses two separate steps for initial parsing and saving (using frosty),
  and then loading (with frosty) and inserting to SQLite.

  Using some post-processing (e.g. to replace different nicknames for people)
  and to remove IRC colors
]#

import std / [
  os, strutils, strformat, 
  db_sqlite, times, sequtils, algorithm, streams,
  marshal, strtabs, monotimes, strscans,
  htmlparser, xmltree, strtabs
]
import irc
import regex
import frosty

{.experimental: "strictFuncs".}

#[
No logs between 2012-07-06T00:00:00Z and 2012-07-04T00:00:00Z!
No logs between 2012-09-26T00:00:00Z and 2012-09-24T00:00:00Z!
No logs between 2012-12-01T00:00:00Z and 2012-11-29T00:00:00Z!
]#
type
  LegacyIrcEvent = object
    case typ: IrcEventType
    of EvConnected:
      nil
    of EvDisconnected:
      nil
    of EvTimeout:
      nil
    of EvMsg:
      cmd: IrcMType
      nick, user, host, servername: string
      numeric: string
      tags: LegacyStringTableRef
      params: seq[string]
      origin: string
      raw: string
      timestamp: int64
  LegacyStringTableRef = ref StringTableObj
  LegacyEntry = tuple[time: int64, msg: LegacyIRCEvent]

  Entry = object
    timestamp: int64
    author: string
    message: string


const logDir = "irclogs"

var dates: seq[DateTime]

var msgs: seq[Entry]

proc parseFile(path: string) = 
  var (dir, name, ext) = path.splitFile()
  if ["backup", "orig", "old2", "old", ".1"].anyIt(it in path): return
  # Some of the filenames contain a weird time like 16-010-2012
  var temp = name.split("-")
  var datestr = name
  if temp[1].len == 3:
    datestr = fmt"{temp[0]}-{temp[1][1 .. ^1]}-{temp[2]}"
  let date = datestr.parse("dd-MM-yyyy", zone = utc())
  dates.add date

  if ext == ".logs":
    var entry: LegacyEntry

    var i = 0
    for line in lines(path):
      if i == 0: 
        inc i 
        continue
      if line.strip() == "": continue
      newStringStream(line).load(entry)
      let ev = entry.msg
      if ev.typ == EvMsg and ev.params.len > 1 and ev.origin[0] == '#':
        msgs.add Entry(timestamp: entry.time, author: ev.nick, message: ev.params[1])
  
  elif ext == ".html":
    let data = loadHtml(path)
    for tr in data.findAll("tr"):
      let ts = (datestr & " " & tr[0].innerText).parse("dd-MM-YYYY HH:mm:ss", zone = utc())
      let nick = tr[1].innerText
      let msg = tr[2].innerText
      # Events like joins/nickname changes, etc
      if nick == "*": continue
      msgs.add Entry(timestamp: ts.toTime.toUnix, author: nick, message: msg)

proc saveInitial = 
  var start = getMonoTime()
  for (pc, path) in walkDir(logDir):
    parseFile(path)
  echo "Parsed all messages!", (getMonoTime() - start)
  start = getMonoTime()

  proc cmpEntry(a, b: Entry): int = 
    cmp(a.timestamp, b.timestamp)

  msgs.sort(cmpEntry)

  var handle = openFileStream("saved", fmWrite)
  msgs.freeze(handle)
  handle.close()
  echo "Saved to disk, took ", (getMonoTime() - start)
  dates.sort()

  var oldDate = "2012-05-30".parse("yyyy-MM-dd")

  for date in dates[1 .. ^1]:
    if (date - oldDate).inDays > 1:
      echo fmt"No logs between {date} and {oldDate}!"
    oldDate = date
  echo "Total msg count - ", msgs.len

import db_sqlite

proc saveSqlite =
  let db = open("irc.db", "", "", "")
  db.exec(sql"drop table if exists log")


  db.exec(sql"""create table log (
                  id   integer primary key,
                  timestamp integer,
                  author text,
                  message text,
                  service text,
                  kind text
                )""")

  let start = getMonoTime()
  var handle = openFileStream("saved", fmRead)

  handle.thaw(msgs)
  echo msgs.len
  echo getMonoTime() - start

  db.exec(sql"begin transaction")

  var oldGitterNick = ""
  for ev in msgs:
    var nick = ev.author
    var origMsg = ev.message.multiReplace({
      "\x02": "", "\x0F": "", 
      "\x01": "", "[discord] ": ""
    })
    var msg = ""
    var action = "Message"
    let service = 
      if nick.startsWith("FromDiscord") or nick.startsWith("GitDisc"):
        if origMsg.startsWith("Uptime - ") or origMsg.startsWith("Don't have info for the current"): continue
        if scanf(origMsg, "ACTION <$+> $+", nick, msg):
          action = "Action"
        elif not scanf(origMsg, "<$+> $+", nick, msg):
          echo "disc error!", repr origMsg, " ", repr nick
          #quit(0)
        "Discord"
      elif nick.endsWith "[m]":
        nick = nick[0 .. ^4]
        msg = origMsg
        "Matrix"
      elif nick.startsWith "FromGitter":
        # Special case for when FromGitter splits big messages
        if origMsg.startsWith("... "):
          nick = oldGitterNick
          msg = origMsg[4 .. ^1]
        # /me action from FromGitter
        elif scanf(origMsg, "ACTION * $+ $+", nick, msg):
          action = "Action"
        elif not scanf(origMsg, "<$+> $+", nick, msg):
          echo "error!", repr origMsg, " ", nick
        oldGitterNick = nick
        "Gitter"
      else:
        if scanf(origMsg, "ACTION * $+", msg):
          action = "Action"
        else:
          msg = origMsg
        "IRC"
    const stripIrc = re"[\x02\x1F\x0F\x16\x1D]|\x03(\d\d?(,\d\d?)?)?"
    msg = msg.replace(stripIrc, "")
    nick = nick.toLowerAscii().strip(chars = {'_'})
    nick = nick.multiReplace({
      "araq_win": "araq",
      "araq0": "araq",
      "araqintrouble": "araq",
      "dom96_and": "dom96",
      "dom96_w": "dom96",
      "dom96-": "dom96",
      "dom96_mobile": "dom96",
      "dom96|w": "dom96",
      "dom96_test": "dom96",
      "zacharycarter_ir": "zacharycarter",
      "zachary carter": "zacharycarter",
      "zachcarter": "zacharycarter",
      "tiberiumn": "yardanico",
      "tiberium": "yardanico",
      "technicae circuit": "technisha circuit",
      "varriount|mobile": "varriount",
      "liblq-dev": "lqdev",
      "alehander42": "alehander92",
      "elegant beef": "never listen to beef",
      "def-pri-pub": "def-",
      "aeverr": "rika"
    })
    db.exec(
      sql"insert into log (timestamp, author, message, service, kind) values (?, ?, ?, ?, ?)",
      ev.timestamp, nick, msg, service, action
    )

  db.exec(sql"end transaction")
  db.close()


#saveInitial()
saveSqlite()