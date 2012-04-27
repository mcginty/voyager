(function() {

  $(document).ready(function() {
    var arteriesMapType, arteriesStyle, home, hulu, map, mapsOptions, oceanOfDehydratedPeeStyle, oceansOfDehydratedPeeMapType, poly, polyOptions, socket;
    arteriesStyle = [
      {
        stylers: [
          {
            visibility: "off"
          }
        ]
      }, {
        stylers: [
          {
            saturation: -99
          }
        ]
      }, {
        featureType: "water",
        stylers: [
          {
            visibility: "simplified"
          }
        ]
      }, {
        featureType: "road.highway",
        stylers: [
          {
            visibility: "on"
          }, {
            saturation: 100
          }, {
            gamma: 1.72
          }, {
            hue: "#ff0900"
          }, {
            lightness: 30
          }
        ]
      }, {
        featureType: "road.highway",
        elementType: "labels",
        stylers: [
          {
            visibility: "on"
          }, {
            hue: "#0044ff"
          }, {
            saturation: -61
          }, {
            lightness: 30
          }
        ]
      }, {
        featureType: "road.local",
        stylers: [
          {
            visibility: "on"
          }, {
            hue: "#ff6e00"
          }, {
            gamma: 0.58
          }, {
            saturation: 97
          }, {
            lightness: 21
          }
        ]
      }, {
        featureType: "road.local",
        stylers: [
          {
            visibility: "on"
          }, {
            hue: "#ff8800"
          }, {
            saturation: 28
          }, {
            lightness: 5
          }, {
            gamma: 0.82
          }
        ]
      }
    ];
    oceanOfDehydratedPeeStyle = [
      {}, {
        featureType: "water",
        stylers: [
          {
            hue: "#ffff00"
          }, {
            saturation: 38
          }, {
            lightness: -28
          }
        ]
      }, {
        featureType: "poi",
        stylers: [
          {
            hue: "#00fff7"
          }, {
            lightness: 41
          }, {
            visibility: "off"
          }
        ]
      }, {
        featureType: "administrative",
        stylers: [
          {
            hue: "#ff1a00"
          }, {
            visibility: "off"
          }
        ]
      }, {
        featureType: "road",
        stylers: [
          {
            lightness: -3
          }, {
            gamma: 0.58
          }, {
            saturation: 56
          }, {
            hue: "#00aaff"
          }
        ]
      }, {
        featureType: "landscape",
        stylers: [
          {
            hue: "#ff006e"
          }, {
            lightness: 100
          }, {
            saturation: -100
          }, {
            visibility: "on"
          }
        ]
      }
    ];
    arteriesMapType = new google.maps.StyledMapType(arteriesStyle, {
      name: "Arteries"
    });
    oceansOfDehydratedPeeMapType = new google.maps.StyledMapType(oceanOfDehydratedPeeStyle, {
      name: "Oceans of Dehydrated Pee"
    });
    mapsOptions = {
      center: new google.maps.LatLng(37.71859032558813, -97.822265625),
      zoom: 5,
      mapTypeControlOptions: {
        mapTypeIds: [google.maps.MapTypeId.SATELLITE, 'arteries', 'oceans_of_dehydrated_pee', google.maps.MapTypeId.ROADMAP, google.maps.MapTypeId.TERRAIN]
      }
    };
    map = new google.maps.Map(document.getElementById("map_canvas"), mapsOptions);
    map.mapTypes.set('oceans_of_dehydrated_pee', oceansOfDehydratedPeeMapType);
    map.mapTypes.set('arteries', arteriesMapType);
    map.setMapTypeId('arteries');
    home = new google.maps.LatLng(40.105957017645, -88.21916878223419);
    hulu = new google.maps.LatLng(34.031344, -118.456717);
    setTimeout((function() {
      return new google.maps.Marker({
        map: map,
        animation: google.maps.Animation.DROP,
        position: home
      });
    }), 500);
    setTimeout((function() {
      return new google.maps.Marker({
        map: map,
        animation: google.maps.Animation.DROP,
        position: hulu
      });
    }), 1000);
    polyOptions = {
      strokeColor: "#2222CC",
      strokeOpacity: 1.0,
      strokeWeight: 2
    };
    poly = new google.maps.Polyline(polyOptions);
    poly.setMap(map);
    socket = io.connect();
    $("#sender").bind("click", function() {
      return socket.emit("message", "Message Sent on " + new Date());
    });
    socket.on("location_backfill", function(pts) {
      var location, path, pt, _i, _len, _results;
      path = poly.getPath();
      _results = [];
      for (_i = 0, _len = pts.length; _i < _len; _i++) {
        pt = pts[_i];
        location = JSON.parse(pt);
        _results.push(path.push(new google.maps.LatLng(location.latitude, location.longitude)));
      }
      return _results;
    });
    return socket.on("location_update", function(data) {
      var path;
      path = poly.getPath();
      return path.push(new google.maps.LatLng(data.latitude, data.longitude));
    });
  });

}).call(this);
