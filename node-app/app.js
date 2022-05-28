var http = require('http');
var ip = require('ip');

function onRequest(req, res){
res.writeHead(200, {'Content-Type':'text/plain'});
res.end('Hello I am ' + ip.address() + '!');
console.log('Incoming connection from ' + req.connection.remoteAddress);
}

var server = http.createServer(onRequest).listen(process.env.PORT);