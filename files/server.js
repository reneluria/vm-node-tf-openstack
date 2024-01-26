// https://nodejs.org/en/learn/getting-started/introduction-to-nodejs#an-example-nodejs-application
const http = require('node:http');

const hostname = '::0';
const port = 8080;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World\n');
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});