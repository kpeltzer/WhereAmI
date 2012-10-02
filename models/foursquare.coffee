config = require '../config'
Node_Foursquare = require("node-foursquare-2")(config)
request = require 'request'
require 'date-utils'
redis = require('redis-url').connect(process.env.REDISTOGO_URL)


class Foursquare
  access = 'GHBZC42PZNDJUW3ET4UFLEU5K30UPQEXSVEH4MNL3PKBYCJK'
  public_venues =
    "4b203c68f964a520232f24e3": "work"
  the_neighborhood_direction_prefixes = [
    "Lower", "Upper"
  ]
  the_neighborhood_cardinal_prefixes = [
    "East", "West"
  ]

  weekend_nights = [5,6]
  weeknights = [1,2,3,4]


  getRecentCheckin: (view) ->
    res = {}
    params=
      afterTimestamp: parseInt((new Date).getTime()/1000) - 9072000 #3.5 months of data
      limit: 250
    Node_Foursquare.Users.getCheckins null, params, access, (error,data) -> 
      ci = data.checkins.items[0]
      d = new Date
      if parseInt(d.getTime()/1000) <= (parseInt(ci.createdAt) + 5400)
        res.singleCheckin = true
        time = ((parseInt(d.getTime()/1000) - parseInt(ci.createdAt))/3600)
        switch true
          when (time >= 1 and time < 1.5) then res.time = "1 hour"
          when time > 1.5 then res.time = "#{Math.round(time)} hours"
          when time < 1 
            t = "#{parseInt(time*60)}"
            t = t.substring(0, t.length - 1) + "0"
            res.time = "#{t} minutes"
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
            res.google = {}
            redis.get ci.id, (err,value) ->
              if value
                res.google = JSON.parse value
              else
                api_request=
                  url: "http://maps.googleapis.com/maps/api/geocode/json?latlng=#{ci.venue.location.lat},#{ci.venue.location.lng}&sensor=false"
                  json: true
                value = request api_request, (error, response, body) ->
                  if !error && body.status =="OK"
                    for a in body.results[0].address_components
                      if "neighborhood" in a.types
                        res.google.neighborhood = generateNeighborhoodString a.long_name
                      else if "locality" in a.types
                        res.google.locality = a.long_name
                      else if "sublocality" in a.types
                        res.google.locality = a.long_name
                    redis.set ci.id, JSON.stringify(res.google)
              view res
      else 
        processHistory(view, data.checkins.items)


  processHistory = (view, cis) ->
    res = {}
    res.singleCheckin = false
    d = new Date
    res.day = d.toFormat "DDDD"
    currentDay = d.getDay()
    currentHour = d.getHours()
    currentTimeCategory = getTimeCategory(currentHour)
    t =  d.toFormat("H:MI")
    res.time = t.substring(0, t.length-1) + "0" + d.toFormat("P") #Estimate to the closest '10' minutes
    #First thing we do is check if its a weeknight and late night. We will just return if this is the case.
    if currentDay in weeknights and currentTimeCategory == -1
      res.hasHistory = false
    else 
      res.hasHistory = true
      checkins = {}
      similarDays = getSimilarDaysArray(currentDay, currentTimeCategory)
      closeHours = getCloseTimesArray(currentHour)
      count = 0
      max = 0
      maxCategories = []
      #Lets find stuff on same day and around the same time.
      for ci in cis
        ciDate = new Date(ci.createdAt*1000)
        ciDateHour = ciDate.getHours()
        ciDateDay = ciDate.getDay()
        if ciDateHour in closeHours and ciDateDay in similarDays
          if ci.venue.categories[0]?     
            name = ci.venue.categories[0].name
          else
            name = 'Mystery venue'
          checkins[name] = 0 unless checkins[name]?
          checkins[name]++
          count++
          switch true
            when checkins[name] > max 
              maxCategories = []
              maxCategories.push getCategoryString(name)
              max++
            when checkins[name] == max then maxCategories.push getCategoryString(name)
    res.types = maxCategories.reverse() if maxCategories and maxCategories.length >= 1
    checkinsArray = generateD3Array checkins
    res.checkins = JSON.stringify [{key: "Where I Might Be", values: checkinsArray}]
    view res
            

  getUser: () ->
    Node_Foursquare.Users.getUser "self", access, (error, data) ->
      return data.user

  testCheckin: () ->
    Node_Foursquare.Users.getCheckins null, null, access, (error,data) -> 
      ci = data.checkins.items[1]
      console.log ci

  generateNeighborhoodString = (neighborhood) ->
    words = neighborhood.split(" ")
    first = words[0]
    second = words[1]
    switch true
      when first in the_neighborhood_direction_prefixes
        if second in the_neighborhood_cardinal_prefixes
          "the #{neighborhood}"
        else
          neighborhood
      when first in the_neighborhood_cardinal_prefixes
        "the #{neighborhood}"
      else
        neighborhood

  getCategoryString = (category) ->
    switch category.charAt(0).toLowerCase()
      when "a","e","i","o","u"
        "an " + category.toLowerCase()
      else
        "a " + category.toLowerCase()

  #returns the time of the day (late night, day, morning)
  getTimeCategory = (hour) ->
    switch true
      #late night
      when 0 <= hour <= 8
        -1
      #Day
      when 8 < hour <= 18
        0
      #night
      else
        1

  getSimilarDaysArray = (currentDay, currentTimeCategory)  ->
    #First switch it by the current day of the week
    switch currentDay
      when 1, 2, 3, 4
        ret = [1,2,3,4]
        ret.push 5 if currentTimeCategory == 0
      when 5
        switch currentTimeCategory
          when 0, -1 then ret = [1,2,3,4,5]
          when 1 then  ret = [6]
      when 6
        switch currentTimeCategory
          when -1, 1 then ret = [5]
          when 0 then ret = [0]
      when 0
        switch currentTimeCategory
          when -1, 1 then ret = []
          when 0 then ret = [6]
      else ret = []
    return ret

  #Returns an array with 'close' hours to a given hour, definied by upper/lower limits
  getCloseTimesArray = (currentHour) ->
    lowerLimit = -3
    upperLimit = 3
    ret = []
    for n in [lowerLimit..upperLimit]
      t = currentHour + n
      switch true
        when t < 0 then t += 24
        when t > 24 then t -= 24
      ret.push t
    return ret

  generateD3Array = (historyData) ->
    ret = []
    for k,v of historyData
      ret.push {"label": k, "value": v}
    return ret

module.exports = Foursquare
