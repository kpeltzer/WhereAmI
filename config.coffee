config = 
  secrets:
    clientId: "LQYIF1AEN2ADLW5KFW0P5TI0VNQYSBUIQBMVPHMKFQ5OEGTB"
    clientSecret: "O4K5ABEUAKZHUWXWV14N5403SBZO3DCE3AS1CTQYRJBU0INW"
    redirectUrl: "http://kenpeltzer.com/whereami"
  log4js:
    appenders: 
      [{type: "console"}]
    levels:
      "node-foursquare-2.Users": "INFO"

module.exports = config
