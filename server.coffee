# NotFound error
NotFound = (msg) ->
  @name = "NotFound"
  Error.call this, msg
  Error.captureStackTrace this, arguments.callee

connect = require "connect"
express = require "express"
colors  = require "colors"
io      = require "socket.io"
encoder = require("./lib/polyline_encoder")
redis   = require("redis").createClient(null,null,{detect_buffers:true})
port    = (process.env.PORT or 8081)
server  = express.createServer()

polyline = new encoder.PolylineEncoder

server.configure ->
  server.set "views", __dirname + "/views"
  server.set "view options",
    layout: false

  server.use connect.bodyParser()
  server.use express.cookieParser()
  server.use express.session(secret: "3136fb857f8c5d891a64fbc0558b46a4")
  server.use connect.static(__dirname + "/static")
  server.use server.router

server.error (err, req, res, next) ->
  if err instanceof NotFound
    res.render "404.jade",
      locals:
        title: "404 - Not Found"
        description: ""
        author: "Jake McGinty"
        analyticssiteid: "UA-322489-6"

      status: 404
  else
    res.render "500.jade",
      locals:
        title: "The Server Encountered an Error"
        description: ""
        author: "Jake McGinty"
        error: err

      status: 500

server.listen port

client_count = 0
io = io.listen(server)
io.sockets.on "connection", (socket) ->
  client_count += 1
  console.log "Client Connected. #{client_count} total connections."
  io.sockets.emit "client_count", client_count
  # Perform a backfill of points in an encoded polyline for minimum bandwidth usage
  # and optimized viewing.
  redis.zrange "trip", 0, -1, (err, pts) ->
    latlngs = []
    for pt in pts
      location = JSON.parse pt
      latlngs.push new encoder.LatLng location.latitude, location.longitude
    encoded = polyline.dpEncode latlngs
    socket.emit "location_backfill", encoded

  socket.on "message", (data) ->
    socket.broadcast.emit "server_message", data
    socket.emit "server_message", data

  socket.on "disconnect", ->
    client_count -= 1
    console.log "Client Disconnected. #{client_count} total connections."
    io.sockets.emit "client_count", client_count

server.get "/", (req, res) ->
  res.render "index.jade",
    locals:
      title: "Trip to Los Angeles"
      description: "Tracking Jake and Lainey's trip to Los Angeles."
      author: "Jake McGinty"

server.post "/report", (req,res) ->
  console.log "#{req.body}"
  id = redis.incr "report"
  redis.zadd "trip", req.body.timestamp, JSON.stringify({
    latitude  : req.body.latitude
    longitude : req.body.longitude
    altitude  : req.body.altitude
    accuracy  : req.body.accuracy
    speed     : req.body.speed
  })
  io.sockets.emit("location_update", req.body)
  res.send (201) # 201 Created is a minimal response to android since it will hang 
                 # until it gets something back.

server.get "/500", (req, res) ->
  throw new Error("This is a 500 Error")

server.get "/*", (req, res) ->
  throw new NotFound

console.log "Listening on http://0.0.0.0:" + port