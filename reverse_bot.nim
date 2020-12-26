import telebot, asyncdispatch, json, httpclient, logging, options, unicode, algorithm
const API_KEY = slurp("secret.key").strip()

proc inlineHandler(b: Telebot, u: InlineQuery): Future[bool] {.async.} =
  if u.query == "": return
  let reversed = $(u.query.toRunes().reversed())
  let res = InlineQueryResultArticle(
    kind: "article",
    title: reversed,
    id: u.id,
    inputMessageContent: InputTextMessageContent(reversed).some
  )

  var results = @[res]
  echo u
  discard waitFor b.answerInlineQuery(u.id, @[res])

when isMainModule:
  let bot = newTeleBot(API_KEY)
  bot.onInlineQuery(inlineHandler)
  bot.poll(timeout = 100, clean = true)