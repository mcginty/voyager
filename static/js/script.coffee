# Author: YOU


$(document).ready ->

  home = new google.maps.LatLng 40.105957017645, -88.21916878223419
  hulu = new google.maps.LatLng 34.031344, -118.456717
  current = null

  speed = new JustGage {
    id: "speed-gauge",
    value: 0,
    title: " ",
    min: 0,
    max: 130,
    label: "m/s",
  }

  arteriesStyle = [
    {
      stylers: [
        { visibility: "off" }
      ]
    },{
      featureType: "water",
      stylers: [
        { visibility: "on" },
        { lightness: -10 },
        { saturation: 57 }
      ]
    },{
      featureType: "road",
      stylers: [
        { visibility: "on" },
        { hue: "#003bff" },
        { saturation: -100 },
        { gamma: 0.89 }
      ]
    }
  ]

  oceanOfDehydratedPeeStyle = [
    {
    },{
      featureType: "water",
      stylers: [
        { hue: "#ffff00" },
        { saturation: 38 },
        { lightness: -28 }
      ]
    },{
      featureType: "poi",
      stylers: [
        { hue: "#00fff7" },
        { lightness: 41 },
        { visibility: "off" }
      ]
    },{
      featureType: "administrative",
      stylers: [
        { hue: "#ff1a00" },
        { visibility: "off" }
      ]
    },{
      featureType: "road",
      stylers: [
        { lightness: -3 },
        { gamma: 0.58 },
        { saturation: 56 },
        { hue: "#00aaff" }
      ]
    },{
      featureType: "landscape",
      stylers: [
        { hue: "#ff006e" },
        { lightness: 100 },
        { saturation: -100 },
        { visibility: "on" }
      ]
    }
  ]
  arteriesMapType = new google.maps.StyledMapType arteriesStyle, {name: "Arteries"}
  oceansOfDehydratedPeeMapType = new google.maps.StyledMapType oceanOfDehydratedPeeStyle, {name: "Oceans of Dehydrated Pee"}

  mapsOptions =
    center: new google.maps.LatLng(37.71859032558813, -97.822265625)
    zoom: 5
    mapTypeControlOptions:
      mapTypeIds: [google.maps.MapTypeId.SATELLITE, 'arteries', 'oceans_of_dehydrated_pee', google.maps.MapTypeId.ROADMAP, google.maps.MapTypeId.TERRAIN]

  map = new google.maps.Map document.getElementById("map_canvas"), mapsOptions

  map.fitBounds new google.maps.LatLngBounds(hulu, home)

  map.mapTypes.set 'oceans_of_dehydrated_pee', oceansOfDehydratedPeeMapType
  map.mapTypes.set 'arteries', arteriesMapType 
  map.setMapTypeId google.maps.MapTypeId.TERRAIN



  setTimeout (->
    title = '<div id="content">Urbana, IL</div>'
    marker = new google.maps.Marker
      map:map
      animation:google.maps.Animation.DROP
      position:home
      icon:"http://www.google.com/mapfiles/marker_black.png"
      title:title

    google.maps.event.addListener marker, 'click', -> (new google.maps.InfoWindow content:title).open(map,marker)
    ), 500

  setTimeout (->
    title = '<div id="content">Santa Monica, CA</div>'
    marker = new google.maps.Marker
      map:map
      animation:google.maps.Animation.DROP
      position:hulu
      icon:"http://www.google.com/mapfiles/marker_black.png"
      title:title

    google.maps.event.addListener marker, 'click', -> (new google.maps.InfoWindow content:title).open(map,marker)
    ), 1000
  polyOptions =
    strokeColor: "#CC2239"
    strokeOpacity: 1.0
    strokeWeight: 2
  poly = new google.maps.Polyline polyOptions
  poly.setMap map

  socket = io.connect()
  $("#sender").bind "click", ->
    socket.emit "message", "Message Sent on " + new Date()

  socket.on "path_backfill", (data) ->
    pts = data.points
    last_point = data.last_point
    path = google.maps.geometry.encoding.decodePath pts.encodedPoints
    return if path.length <= 0
    poly.setPath path
    current = new google.maps.Marker
      map:map
      animation:google.maps.Animation.DROP
      position:path[path.length-1]
      icon:'http://labs.google.com/ridefinder/images/mm_20_red.png'
    speed.refresh last_point.speed
    $("#last_seen_time").html new Date(parseInt(last_point.timestamp)).toString()
    $("#last_seen_time").easydate()

  socket.on "client_count", (count) ->
    $("#client_count").html if count == 1 then "1 user" else "#{count} users"

  socket.on "location_update", (data) ->
    path = poly.getPath()
    latlng = new google.maps.LatLng data.latitude, data.longitude
    path.push latlng
    current.setPosition latlng
    $("#last_seen_time").html data.timestamp
    speed.refresh data.speed