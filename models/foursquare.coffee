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
    params=
      afterTimestamp: parseInt((new Date).getTime()/1000) - 7776000
      limit: 250
    Node_Foursquare.Users.getCheckins null, params, access, (error,data) -> 
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
      else 
        getHistory(view, data.checkins.items)


  getHistory = (view, cis) ->
    res = {}
    res.checkin = false
    d = Date.today()
    res.day = d.toFormat "DDDD"
    currentDay = d.getDay()
    currentHour = d.getHour()
    currentTimeCategory = getTimeCategory(currentHour)
    t =  d.toFormat("H:MM")
    res.time = t.substring(0, t-1) + "0" #Estimate to the closest '10' minutes

    #First thing we do is check if its a weeknight and late night. We will just return if this is the case.
    if currentDay in weekend_nights and currentTimeCategory == -1
      res.hasHistory = false
    else 
      res.hasHistory = true
      firstPriority = secondPriority = []
      similarDays = getSimilarDaysArray(currentDay, currentTimeCategory)
      #Lets find stuff on same day and around the same time.
      for ci in cis.items
        ciDate = new Date(ci.createdAt*1000)
        ciDateHour = ciDate.getHour()
        ciDateDay = ciDate.getDay()
        if isCloseTime(ciDateHour, currentHour)
          #If day is the same, add it to primary list
          if ciDateDay == currentDay
            firstPriority.push ci
          #Else we have to see if its ok to put on secondary list
          else if ciDateDay in similarDays
            secondPriority.push ci
    view res
            
            


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

  #Returns if hour given from Date.getHour is close enough to be similar
  isCloseTime = (checkinHour, currentHour) ->
    return (currentHour -3) < checkinHour < (currentHour + 3)

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

module.exports = Foursquare
