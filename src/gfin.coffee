# quant 0.0.1 - some tools for finance
# 
# Copyright (c) 2012 Andrew Wild (akohdr@gmail.com)
# Licensed under the MIT (MIT-LICENSE.txt) licence.

request = require('request')
parseJSON =
    #eval(data) # VERY BAD idea on untrusted env
    (data) -> eval('('+data+')') # a little better () prevent some code injections
    #JSON.parse(data) # slower but safe BUT requires quoted attribute names which google does't natively output

gfinUrl = 'http://www.google.com/finance/'
baseUrl = gfinUrl+'option_chain?output=json&q='
quote_url_front = (symbol) -> baseUrl+symbol
quote_url = (symbol, expiry) -> baseUrl+ symbol+'&expd='+expiry.d+'&expm='+expiry.m+'&expy='+expiry.y

MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

make_date = (jsDate)-> {d:jsDate.getDate(), m:jsDate.getMonth(), y:jsDate.getFullYear()}

make_range = (jsStartDate, jsEndDate) -> {start: make_date(jsStartDate), end: make_date(jsEndDate)}

year_prior = (jsDate) ->
	yearPrior = new Date(jsDate)
	yearPrior.setFullYear(yearPrior.getFullYear()-1)
	return yearPrior

past_year = () -> make_range(year_prior(now = new Date), now)

historical_url = (symbol,range) -> (
    s = range.start
    e = range.end
    gfinUrl+'historical?q='+symbol+'&startdate='+MONTHS[s.m]+'+'+s.d+'%2C+'+s.y+
           '&enddate='+MONTHS[e.m]+'+'+e.d+'%2C+'+e.y+'&output=csv'
           #'&startdate=Apr+1%2C+2011&enddate=Apr+3%2C+2012&num=30&output=csv'
)

chain = (symbol, expiry, callback) ->
    request({uri: quote_url(symbol, expiry)},
            (error, response, body) ->  callback parseJSON(body))?

front = (symbol, callback) ->
	request({uri: quote_url_front(symbol)},
            (error, response, body) -> if(!error? && response?.statusCode == 200)
		            callback(parseJSON(body))
	            else
		            console.log("Error retrieving quote: "+error?+' response:'+response?+' body:'+body?)
	)?

expirations = (symbol, callback) -> front(symbol, (front) -> callback front.expirations)

options = (symbol, exps, os) -> (chain(symbol, m, (o) -> os.push(o) )) for m in exps; os

chains = (symbol, callback) ->
            expirations(symbol, (exps) ->
                callback(options(symbol, exps, [])))

daily = (symbol, range, callback) ->
	request({uri:historical_url(symbol, range)},
            (error, response, body) -> if(!error? && response?.statusCode == 200)
		            callback(body.split('\n').map((o) -> o.split(',')))
	            else
		            console.log("Error retrieving quote: "+error)
	)?

e = exports
e.chain = chain
e.chains = chains
e.front = front
e.expirations = expirations
e.daily = daily
e.make_date = make_date
e.make_range = make_range
e.year_prior = year_prior
e.past_year = past_year

