var express = require('express');
var vhost = require('vhost');
var app = express();

app.use(vhost('hook.website.labeli.org', require('./hook.js')));

app.use(express.static(__dirname));
app.get('*', function(req, res){ res.sendFile(__dirname + '/index.html'); });

module.exports = app;