import std/[strutils, httpclient, tables, unicode, md5]

const 
  outDir = "avatars"
  usersFile = "users.txt"

  normalizedMapping = {
    "Andreas Rumpf": "Andreas Rumpf (Araq)",
    "Araq": "Andreas Rumpf (Araq)",

    "Dominik Picheta": "Dominik Picheta (dom96)",
    "dom96": "Dominik Picheta (dom96)",
    
    "Yuriy Glukhov": "Yuriy Glukhov (yglukhov)",
    "yglukhov": "Yuriy Glukhov (yglukhov)",

    "Zahary Karadjov": "Zahary Karadjov (zah)",
    "zah": "Zahary Karadjov (zah)",

    "Ganesh Viswanathan": "Ganesh Viswanathan (genotrace)",
    "genotrace": "Ganesh Viswanathan (genotrace)",

    "Danil Yarantsev": "Danil Yarantsev (Yardanico)",
    "Daniil Yarancev": "Danil Yarantsev (Yardanico)",

    "Dennis Felsing": "Dennis Felsing (def)",
    "def": "Dennis Felsing (def)",

    "alaviss": "Leorize",

    "Dmitry Atamanov": "Dmitry Atamanov (data-man)",
    "data-man": "Dmitry Atamanov (data-man)",
    
    "Miran": "narimiran",

    "Mamy André-Ratsimbazafy": "Mamy Ratsimbazafy (mratsim)",
    "Mamy Ratsimbazafy": "Mamy Ratsimbazafy (mratsim)",

    "Constantine Molchanov": "Constantine Molchanov (moigagoo)",
    "Константин Молчанов": "Constantine Molchanov (moigagoo)",
    "Konstantin Molchanov": "Constantine Molchanov (moigagoo)",
    
    "gmpreussner": "Gerke Max Preussner (gmpreussner)",
    "cooldome": "Andrii Riabushenko (cooldome)"
  }.toTable

var userToEmail: Table[string, string]

for line in lines(usersFile):
  # only split once in a rare case there's a colon in a name
  let data = line.split(':', maxsplit = 1)
  # not a full entry
  if data[0].len == 0:
    continue
  
  var (email, name) = (data[0], data[1])
  let maybeName = normalizedMapping.getOrDefault(name)
  if maybeName != "": name = maybeName

  userToEmail[name] = email

echo userToEmail.len