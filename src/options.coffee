
jspath = require 'JSONPath'

# pull out only put/call object from provides options tree
strip = (os) -> jspath.eval os,'$..[calls,puts]..'

# matches and capture symbol names provided from gfin
symbolRE = /(\w+)(\d\d)(\d\d)(\d\d)([C|P])(.*)$/
humanForm = (o) -> "#{o.dd}/#{o.mm}/20#{o.yy} #{o.r} $#{o.s} #{if o.t=='C' then 'call' else 'put'}"
parseName = (n) -> [n,r,yy,mm,dd,t,s] = n.match symbolRE; {n,r,yy,mm,dd,t,s}

emptyIndex = ->
    bySymbol: {}
    byStrike: {}
    byExpiry: {}

keys = (l) -> k for k of l

# Curryable add
addToListCurried = (l) -> (k) -> (o) -> (if k of l then l[k] else l[k] = []).push o

# Bound add
addToList = (l,k,o) -> ((addToListCurried l) k) o

addToIndex = (ix) -> (o) ->
    ix.bySymbol[o.s] = o
#    xs = ix.byStrike; s = o.strike
#    (if s of xs then xs[s] else xs[s] = []).push o
#    xe = ix.byExpiry; e = o.expiry
#    (if e of xe then xe[e] else xe[e] = []).push o
    addToList ix.byStrike, o.strike, o
    addToList ix.byExpiry, o.expiry, o
    o

index = (os, ix = emptyIndex()) -> os.map addToIndex ix; ix

e = exports
e.strip = strip
e.humanForm = humanForm
e.parseName = parseName
e.index = index
e.addToList = addToListCurried

# Some useful funcs

e.strikes = (ix) -> keys ix.byStrike
e.expirations = (ix) -> keys ix.byExpiry # likely quicker pulling this of front
e.symbols = (ix) -> keys  ix.bySymbol
