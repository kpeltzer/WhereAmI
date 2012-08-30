express = require 'express'
stylus = require 'stylus'

app = express()
pub = __dirname + '/public'

app.use app.router
app.use express.static(pub)
app.use express.errorHandler()

app.set "view engine", "jade"
app.use(stylus.middleware debug: true, src: __dirname+"/public/stylesheets", compile: compileMethod)

compileMethod = (str, path) ->
  stylus(str)
    .set('filename', path)
    .set('compress', true)


app.get '/', (request, response) -> 
  Foursquare = require './models/foursquare.coffee'
  fs = new Foursquare
  response.send(fs.getUser())

port = process.env.PORT || 5000
app.listen port, () ->
  console.log("Listening on " + port)
