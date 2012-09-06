express = require 'express'
stylus = require 'stylus'

app = express()
pub = __dirname + '/public'

app.use app.router
app.use express.errorHandler()

app.set 'views', __dirname + '/views'
app.set "view engine", "jade"

compile = (str, path) ->
  return stylus(str)
    .set('filename', path)
    .set('warn', true)
    .set('compress', true)

app.use stylus.middleware
  src: pub + '/stylesheets'
  compile: compile

app.use express.static(pub)

app.get '/', (request, response) -> 
  Foursquare = require './models/foursquare.coffee'
  fs = new Foursquare
  res = fs.getRecentCheckin()
  console.log res
  if res
    checkin = true
    response.render 'checkin', {res: res, recentCheckin: checkin}
  else
  	checkin = false
  	#res = fs.getHistory()
    #response.render
    
app.get '/test', (request, response) ->
  Foursquare = require './models/foursquare.coffee'
  fs = new Foursquare
  response.send(fs.testFunc())

port = process.env.PORT || 5000
app.listen port, () ->
  console.log("Listening on " + port)
