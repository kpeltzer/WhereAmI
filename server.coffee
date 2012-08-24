express = require 'express'

app = express()

access = 'GHBZC42PZNDJUW3ET4UFLEU5K30UPQEXSVEH4MNL3PKBYCJK'

app.get '/', (request, response) -> 
  config = require './config'
  Foursquare = require('node-foursquare-2')(config)
  response.send("hello")

port = process.env.PORT || 5000
app.listen port, () ->
  console.log("Listening on " + port)
