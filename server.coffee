express = require 'express'
stylus = require 'stylus'

app = express()
pub = __dirname + '/public'
views = __dirname + '/views'

app.use app.router
app.use express.errorHandler()

app.set 'views', __dirname + '/views'
app.set "view engine", "jade"

compile = (str, path) ->
  return stylus(str)
    .set('filename', path)
    .set('compress', true)

app.use stylus.middleware
  src: views
  dest: pub
  compile: compile

app.use express.static(pub)

app.get '/', (request, response) -> 
  Foursquare = require './models/foursquare.coffee'
  fs = new Foursquare
  fs.getRecentCheckin (res) ->
    response.render 'checkin', {res: res}
    
app.get '/test', (request, response) ->
  Foursquare = require './models/foursquare.coffee'
  fs = new Foursquare
  fs.getHistory (res) ->
    response.render 'checkin', {res: res}

port = process.env.PORT || 5000
app.listen port, () ->
  console.log("Listening on " + port)