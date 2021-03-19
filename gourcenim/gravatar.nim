import std/[strutils, httpclient, tables, unicode, md5]
import common

const
  outDir = "avatars"
  usersFile = "users.txt"

proc getEmails = 
  var userToEmail: Table[string, string]

  for line in lines(usersFile):
    # only split once in a rare case there's a colon in a name
    let data = line.split(':', maxsplit = 1)
    # not a full entry
    if data[0].len == 0:
      continue
    
    var (email, name) = (data[0], data[1])
    let maybeName = normalizedMappingTable.getOrDefault(name)
    if maybeName != "": name = maybeName

    userToEmail[name] = email

const gourceLog = "nimrepo.txt"
proc fixGourceLog = 
  var newFile = open("nimfixed.txt", fmWrite)

  # We can't use multiReplace because filenames
  # might intersect with usernames
  for line in lines(gourceLog):
    # format is
    # 1214144051|Andreas Rumpf|A|/configure
    # timestamp|name|action|path
    var data = line.split('|')
    doAssert data.len == 4, line

    # replace the name
    let maybeName = normalizedMappingTable.getOrDefault(data[1])
    if maybeName != "": data[1] = maybeName

    newFile.writeLine(data.join("|"))
  
  newFile.close()

fixGourceLog()