var http     = require('http')
,   fs       = require('fs')
,   Pathname = require('path')
,   Url      = require('url')
,   Crypto   = require('crypto')
,   Mime     = require('./mime_types')
;

var $server
,   $roots    = []
,   $port     = 3000
,   $fallback
;

var _send_file
,   _pipe_file
,   _send_304
,   _send_404
,   _send_500
;

(function(){
  var state = 0
  ;
  
  process.argv.forEach(function(val){
    switch (state) {
    case 0:
      if ((val == '--port')     || (val == '-p')) { state = 1; }
      if ((val == '--root')     || (val == '-r')) { state = 2; }
      if ((val == '--fallback') || (val == '-f')) { state = 3; }
      break;
      
    case 1:
      state = 0
      $port = parseInt(val, 10);
      break;
      
    case 2:
      state = 0
      $roots.push(Pathname.normalize(val));
      break;
      
    case 3:
      state = 0
      $fallback = Pathname.normalize(val);
      break;
    }
  });
})();

(function(){
  $server = http.createServer(function (req, res) {
    var url
    ;
    
    if (req.method != 'GET' && req.method != 'HEAD') {
      _send_404(res);
      return;
    }
    
    url = Url.parse(req.url);
    
    _send_file(req, res, url.pathname, $roots, $fallback);
  });
  
  $server.listen($port);
})();

_send_file = function(req, res, path, roots, fallback){
  var paths = []
  ;
  
  roots.forEach(function(root){
    paths.push(Pathname.join(root, path));
  });
  
  if (fallback) {
    paths.push(fallback);
  }
  
  _pipe_file(req, res, paths);
};

_pipe_file = function(req, res, paths){
  var path = paths.shift()
  ,   stream
  ,   mime
  ;
  
  if (!path) {
    _send_404(res);
    return;
  }
  
  fs.stat(path, function(err, stat){
    if (err) {
      _pipe_file(req, res, paths);
      return;
    }
    
    if (!stat.isFile()) {
      paths.unshift(Pathname.join(path, 'index.html'));
      _pipe_file(req, res, paths);
      return;
    }
    
    mime = Mime[Pathname.extname(path).toLowerCase()];
    if (!mime) { mime = 'application/octet-stream'; }
    if (mime == '#skip') {
      _send_404(res);
      return;
    }
    
    etag = Crypto.createHash('md5');
    etag.update(''+stat.ctime);
    etag.update(''+stat.mtime);
    etag.update(''+stat.size);
    etag.update(''+stat.ino);
    etag = "md5-" + etag.digest('hex');
    
    if (req.headers['if-none-match'] == etag) {
      _send_304(res);
      return;
    }
    
    res.writeHead(200,
    { 'Content-Type'   : mime
    , 'Content-Length' : stat.size
    , 'ETag'           : etag
    });
    
    stream = fs.createReadStream(path);
    
    stream.pipe(res);
    
    stream.on('error', function(err){
      console.log(err);
      res.end();
    });
  });
};

_send_304 = function(res){
  res.writeHead(304, {});
  res.end();
};

_send_404 = function(res){
  res.writeHead(404, {'Content-Type': 'text/plain'});
  res.end('404 - Not found.\n');
};

_send_500 = function(res){
  res.writeHead(500, {'Content-Type': 'text/plain'});
  res.end('500 - Internal server error.\n');
};