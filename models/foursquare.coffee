config = require '../config'
Node_Foursquare = require("node-foursquare-2")(config)
request = require 'request'
require 'date-utils'


class Foursquare
  access = 'GHBZC42PZNDJUW3ET4UFLEU5K30UPQEXSVEH4MNL3PKBYCJK'
  public_venues =
    "4b203c68f964a520232f24e3": "work"
  the_neighborhood_prefixes = [
    "Lower", "Upper", "East", "West"
  ]

  getRecentCheckin: (view) ->
    res = {}
    Node_Foursquare.Users.getCheckins null, null, access, (error,data) -> 
      ci = data.checkins.items[0]
      console.log ci
      d = new Date
      #if parseFloat(d.getTime()/100) <= (parseInt(ci.createdAt) + 3600)
      if true
        res.checkin = true
        time = ((parseInt(d.getTime()/1000) - parseInt(ci.createdAt))/3600)
        switch true
          when (time >= 1 and time < 1.5) then res.time = "1 hour"
          when time > 1.5 then res.time = "#{parseInt(time)} hours"
          when time < 1 then res.time = "#{parseInt(time*60)} minutes"
        if public_venues[ci.venue.id] #public checkin
          res.public = true
          res.name = ci.venue.name
          switch public_venues[ci.venue.id]
            when "work"
              res.extra = "at work"
          view res
        else
          res.public = false
          res.category = getCategoryString ci.venue.categories[0].name
          if ci.venue.location.lat && ci.venue.location.lng
            #Call Google Geolocation API
            api_request=
              url: "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{ci.venue.location.lat},#{ci.venue.location.lng}&sensor=false"
              json: true
            value = request api_request, (error, response, body) ->
              if !error && body.status =="OK"
                for a in body.results[0].address_components
                  if "neighborhood" in a.types
                    res.neighborhood = generateNeighborhoodString a.long_name
                  else if "locality" in a.types
                    res.locality = a.long_name
                  else if "sublocality" in a.types
                    res.locality = a.long_name
                view res


  getHistory: () ->
    res = {}
    d = Date.today()
    res.day = d.toFormat "DDDD"
    t =  d.toFormat("H:MM")
    res.time = t.substring(0, t-1) + "0"
    params=
      afterTimestamp: parseFloat((new Date).getTime/100) - 7776000
      limit: 250
    Node_Foursquare.Users.getCheckins null, params, access, (error, data) ->

  getUser: () ->
    Node_Foursquare.Users.getUser "self", access, (error, data) ->
      return data.user

  testCheckin: () ->
    Node_Foursquare.Users.getCheckins null, null, access, (error,data) -> 
      ci = data.checkins.items[1]
      console.log ci

  generateNeighborhoodString = (neighborhood) ->
    first = neighborhood.split(" ")[0]
    if first in the_neighborhood_prefixes
      "the #{neighborhood}"
    else
      neighborhood

  getCategoryString = (category) ->
    switch category.charAt(0)
      when "a","e","i","o","u"
        "an " + category.toLowerCase()
      else
        "a " + category.toLowerCase()

module.exports = Foursquare