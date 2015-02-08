var express = require('express');
var app = express();

// static content
app.use(express.static(__dirname));

// return index.html for all other routes
app.get('*', function(req, res)
{
    res.sendFile(__dirname + '/index.html');
});

app.listen(80, function() {
  console.log('server.js running');
});