import std/[
  os, strutils, httpclient,
  tables, unicode, md5, strscans
]
import common

const
  outDir = "avatars"
  usersFile = "users.txt"


# See https://docs.github.com/en/rest/reference/repos#list-commits
# Our goal is to get all avatars for all commits and map them
# to the names that we have



proc getEmails: Table[string, string] = 
  for line in lines(usersFile):
    # only split once in a rare case there's a colon in a name
    let data = line.split(':', maxsplit = 1)
    # not a full entry
    if data[0].len == 0:
      continue
    
    var (email, name) = (data[0], data[1])
    let maybeName = normalizedMappingTable.getOrDefault(name)
    if maybeName != "": name = maybeName

    result[name] = email

proc downloadAvatars(users: Table[string, string]) = 
  for name, email in users:
    var ghId, ghName, temp: string
    var url = "https://avatars.githubusercontent.com/"
    # 106477+ba0f3@users.noreply.github.com:Huy
    # get avatar from the user id or username
    if scanf(email, "$++$+@users.noreply.github.com", ghId, ghName):
      url.add "u/" & ghId & "?size=90"
    elif scanf(email, "$+@users.noreply.github.com", ghName):
      url.add ghName & "?size=90"
    else:
      url = "https://www.gravatar.com/avatar/" & getMd5(email) & "?d=404&size=90"
    echo name, " ", url

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

let emails = getEmails()
downloadAvatars(emails)
fixGourceLog()