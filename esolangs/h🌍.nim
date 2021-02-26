# https://esolangs.org/wiki/H%F0%9F%8C%8D
import std/strutils

let code = "hh\nTHIS IS A SIMPLE QUINE.\nww\nhw\nwh\nq"
# for line in stdin.lines():
for line in code.splitLines():
  echo case line
  of "hh": "Hello, Hello!"
  of "ww": "World, World!"
  of "hw": "Hello, World!"
  of "wh": "World, Hello!"
  of "h": "Hello!"
  of "w": "World!"
  of "q": quit(0)
  else: line