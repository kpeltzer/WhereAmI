config = require '../config'
Node_Foursquare = require("node-foursquare-2")(config)

class Foursquare
  access = 'GHBZC42PZNDJUW3ET4UFLEU5K30UPQEXSVEH4MNL3PKBYCJK'

  getRecentCheckin: () ->
    Node_Foursquare.Users.getCheckins null, null, access, (error,data) -> 
      ci = data.items[0]
      d = new Date
      if parseFloat(d.getTime) <= (parseInt(ci.createdAt) + 3600)
        return ci
      else
        return false

  getUser: () ->
    Node_Foursquare.Users.getUser "self", access, (error, data) ->
      return data.user

module.exports = Foursquare