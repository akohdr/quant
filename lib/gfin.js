/* quant 0.0.1 - some tools for finance
 *
 * Copyright (c) 2012 Andrew Wild (akohdr@gmail.com)
 * Licensed under the MIT (MIT-LICENSE.txt) licence.
 */

var request = require('request');
var jspath = require('JSONPath');

var max_month = {'d':1, 'm':1, 'y':2016};

function parseJSON (data) {
    //return json = eval(data); // VERY BAD idea on untrusted env
    return json = eval('('+data+')'); // a little better () prevent some code injections
    //return data = JSON.parse(jsonStr); // slower but safe BUT requires quoted attribute names
}

function quote_url_front (symbol) {
    return 'http://www.google.com/finance/option_chain?output=json&q='+symbol;
}

function quote_url (symbol, expiry) {
    return 'http://www.google.com/finance/option_chain?output=json&q='+
           symbol+'&expd='+expiry.d+'&expm='+expiry.m+'&expy='+expiry.y;
}

MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function historical_url (symbol,range) {
    var s=range.start, e=range.end;
    return 'http://www.google.com/finance/historical?q='+symbol+
           '&startdate='+MONTHS[s.m]+'+'+s.d+'%2C+'+s.y+
           '&enddate='+MONTHS[e.m]+'+'+e.d+'%2C+'+e.y+
           '&output=csv';
           //'&startdate=Apr+1%2C+2011&enddate=Apr+3%2C+2012&num=30&output=csv'
}

var reqCount = 0;
var chains = '{ "chains": [';
exports.chain = function (symbol, expiry, callback) {
    reqCount++;
    request({uri: quote_url(symbol, expiry)}, function(error, response, body) {
        chains += (body + ((--reqCount < 1) ? ']}\n' : ','));
	if(reqCount == 0) {
		//console.log(chains);
		callback(parseJSON(chains));
	}
	//if(reqCount == 0) callback(chains);
    });
}

exports.chains = function (symbol, callback) {
	request({uri: quote_url(symbol, max_month)}, function(error, response, body) {
	if(!error && response.statusCode == 200) {
		var data = parseJSON(body);
        	for (i in data.expirations)
        	    	options = exports.chain(symbol, data.expirations[i], callback);
	}
	else
		console.log('Error retrieving quote: '+error);
	});
}

exports.front = function (symbol, callback) { 
	request({uri: quote_url_front(symbol)}, function(error, response, body) {
	if(!error && response.statusCode == 200) 
		callback(parseJSON(body));
	else
		console.log("Error retrieving quote: "+error);
	});
}

exports.fromUrl = function (url, callback) { 
	request(url, function(error, response, body) {
	if(!error && response.statusCode == 200) 
		callback(parseJSON(body));
	else
		console.log("Error retrieving quote: "+error);
	});
}

exports.expirations = function(symbol, callback) {
	exports.front(symbol, function(front) {
		callback(jspath.eval(front, "$..expirations")[0]);
	});
}


exports.daily = function (symbol, range, callback) {
	request({uri:historical_url(symbol, range)}, function(error, response, body) {
	if(!error && response.statusCode == 200) 
		callback(body.split('\n').map(function(o) {return o.split(',')}));
	else
		console.log("Error retrieving quote: "+error);
	});
}

exports.make_date = function (jsDate){
	return {d:jsDate.getDate(), m:jsDate.getMonth(), y:jsDate.getFullYear()};
}

exports.make_range = function (jsStartDate, jsEndDate) {
	return {start: exports.make_date(jsStartDate), end: exports.make_date(jsEndDate)}
}

exports.year_prior = function (jsDate) {
	var yearPrior = new Date(jsDate)
	yearPrior.setFullYear(yearPrior.getFullYear()-1);
	return yearPrior;
}

exports.past_year = function () {
    var now = new Date() 
    return exports.make_range(exports.year_prior(now), now)
}


