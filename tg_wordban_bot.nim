# This file implements a relatively simple Telegram bot
# for "banning" specific words or phrases. Intended
# to be used as a game, like trying to write messages without 
# the word "that" or without the letter "a"
import asyncdispatch, logging, options
import strformat, sequtils, unicode
import strutils except strip, split

import telebot

var L = newConsoleLogger(fmtStr="$levelname, [$time] ")
addHandler(L)

const ApiKey = slurp("secret.key")

# Sequence of all currently forbidden words
var forbiddenWords = newSeq[string]()
# Current mode - In "contains" we just check if the string contains any 
# of the forbidden words. In "words" (which is default) we check 
# if there's a separate word matching the ones we have in forbiddenWords
var containsMode = false

proc sendMsg(b: Telebot, c: Command, msg: string) = 
  ## A convenience proc for the template below to 
  ## make constructing messages much cleaner
  var message = newMessage(c.message.chat.id, msg)
  message.disableNotification = true
  message.replyToMessageId = c.message.messageId
  message.parseMode = "markdown"
  asyncCheck b.send(message)

template sendMsg(msg: string) {.dirty.} = 
  sendMsg(b, c, msg)

proc updateHandler(b: Telebot, u: Update) {.async.} =
  # If we don't need to handle any forbidden words at all
  if forbiddenWords.len == 0: return
  var msg: Message
  # We handle messages or edits
  if u.message.isSome():
    msg = u.message.get()
  elif u.editedMessage.isSome():
    msg = u.editedMessage.get()
  else: return
  # If there's no text -> skip
  if not msg.text.isSome(): return
  
  # Lowercase since it wouldn't really make sense to differentiate by case
  let text = msg.text.get().toLower()
  # Remove punctuation, leading/following whitespaces and spllit into tokens
  let tokens = text.multiReplace(
    {":": " ", "!": " ", "." : " ", "?": " "}
  ).strip().split() 
  if anyIt(forbiddenWords, it in tokens or (containsMode and it in text)):
    asyncCheck b.deleteMessage($msg.chat.id, msg.messageId)

proc startword(b: Telebot, c: Command) {.async.} = 
  let data = c.params.strip()
  if data.len == 0: 
    sendMsg "Usage: /startword <word>"
    return
  else:
    # Try to find that word in our forbidden word list
    let idx = forbiddenWords.find(data)
    if idx != -1:
      sendMsg "This word is already forbidden"
    else:
      forbiddenWords.add data
      sendMsg &"Added new forbidden word `{data}`"

proc stopword(b: Telebot, c: Command) {.async.} = 
  let data = c.params.strip()
  if data.len == 0: 
    sendMsg "Usage: /stopword <word> or /stopword <wordindex>"
    return
  var removedWord = ""
  # If that string is a number
  if data.allIt(it in Digits):
    # Wrap in try block because that number might be bigger than int64
    let num = try: 
      parseInt(data) 
    except: 
      sendMsg "Incorrect word index"
      return
    # If that num is a valid index
    if num <= (forbiddenWords.len-1):
      removedWord = forbiddenWords[num]
      forbiddenWords.delete(num)
  # Find that word in forbidden words and remove it
  else:
    let idx = forbiddenWords.find(data)
    if idx == -1:
      sendMsg("This word isn't forbidden")
      return
    else:
      removedWord = data
      forbiddenWords.delete idx
  sendMsg &"Removed forbidden word `{removedWord}`"

proc listwords(b: Telebot, c: Command) {.async.} = 
  if forbiddenWords.len == 0:
    sendMsg "There are no forbidden words yet, add one with /startword <word>"
    return
  else:
    var msg = "List of currently forbidden words:\n"
    for i, word in forbiddenWords:
      msg &= &"{i} - {word}\n"
    sendMsg(msg)

proc mode(b: Telebot, c: Command) {.async.} = 
  let data = c.params.strip().split()
  if data.len == 0 or data[0] notin ["contains", "word"]:
    sendMsg "To change the mode use /mode contains or /mode word"
    return
  containsMode = if data[0] == "contains": true else: false
  if containsMode: 
    sendMsg "Switched detection mode to `contains`"
  else:
    sendMsg "Switched detection mode to `word`"

when isMainModule:
  let bot = newTeleBot(ApiKey)

  bot.onUpdate(updateHandler)
  bot.onCommand("startword", startword)
  bot.onCommand("stopword", stopword)
  bot.onCommand("listwords", listwords)
  bot.onCommand("mode", mode)
  bot.poll(timeout=50)