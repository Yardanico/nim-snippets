import std/tables
export tables
const 
  normalizedMapping* = {
    "rumpf_a@web.de": "Andreas Rumpf (Araq)",
    "Rumpf": "Andreas Rumpf (Araq)",
    "Andreas Rumpf": "Andreas Rumpf (Araq)",
    "Araq": "Andreas Rumpf (Araq)",

    "Dominik Picheta": "Dominik Picheta (dom96)",
    "dom96": "Dominik Picheta (dom96)",
    
    "Yuriy Glukhov": "Yuriy Glukhov (yglukhov)",
    "yglukhov": "Yuriy Glukhov (yglukhov)",

    "Grzegorz Adam Hankiewicz": "Grzegorz Adam Hankiewicz (gradha)",

    "Zahary Karadjov": "Zahary Karadjov (zah)",
    "zah": "Zahary Karadjov (zah)",

    "Saem Ghani": "Saem Ghani (saem)",

    "Arne Döring": "Arne Döring (krux02)",

    "Andy Davidoff": "Andy Davidoff (disruptek)",
    "Bad Dog": "Andy Davidoff (disruptek)",

    "Ganesh Viswanathan": "Ganesh Viswanathan (genotrace)",
    "genotrace": "Ganesh Viswanathan (genotrace)",

    "Danil Yarantsev": "Danil Yarantsev (Yardanico)",
    "Daniil Yarancev": "Danil Yarantsev (Yardanico)",

    "Dennis Felsing": "Dennis Felsing (def)",
    "def": "Dennis Felsing (def)",

    "reactormonk": "Simon Hafner (reactormonk)",
    "Simon Hafner": "Simon Hafner (reactormonk)",

    "alaviss": "Leorize",

    "Sebastian Schmidt": "Sebastian Schmidt (Vindaar)",
    "Vindaar": "Sebastian Schmidt (Vindaar)",

    "Eugene Kabanov": "Eugene Kabanov (cheatfate)",
    "cheatfate": "Eugene Kabanov (cheatfate)",

    "Euan": "euantorano",
    "Euan T": "euantorano",
    "Euan Torano": "euantorano",

    "ephja": "Erik Johansson Andersson (ephja)",
    "Erik Johansson Andersson": "Erik Johansson Andersson (ephja)",

    "enthus1ast": "David Krause (enthus1ast)",
    "David Krause": "David Krause (enthus1ast)",

    "Ico Doornekamp": "Ico Doornekamp (zevv)",

    "hlaff": "hlaaftana",

    "flaviut": "Flaviu Tamas (flaviut)",
    "Flaviu Tamas": "Flaviu Tamas (flaviut)",

    "Oscar Nihlgård": "Oscar Nihlgård (GULPF)",

    "Jacek Sieka": "Jacek Sieka (arnetheduck)",

    "Clay Sweetser": "Clay Sweetser (Varriount)",
    "Varriount": "Clay Sweetser (Varriount)",

    "nc-x": "Neelesh Chandola (nc-x)",
    "Neelesh Chandola": "Neelesh Chandola (nc-x)",

    "Charles Blake": "Charles Blake (cblake)",

    "Dmitry Atamanov": "Dmitry Atamanov (data-man)",
    "data-man": "Dmitry Atamanov (data-man)",
    
    "Miran": "narimiran",

    "Mamy André-Ratsimbazafy": "Mamy Ratsimbazafy (mratsim)",
    "Mamy Ratsimbazafy": "Mamy Ratsimbazafy (mratsim)",

    "Constantine Molchanov": "Constantine Molchanov (moigagoo)",
    "Константин Молчанов": "Constantine Molchanov (moigagoo)",
    "Konstantin Molchanov": "Constantine Molchanov (moigagoo)",

    "Andrey Makarov": "Andrey Makarov (a-mr)",

    "gmpreussner": "Gerke Max Preussner (gmpreussner)",
    "cooldome": "Andrii Riabushenko (cooldome)"
  }

  normalizedMappingTable* = normalizedMapping.toTable()