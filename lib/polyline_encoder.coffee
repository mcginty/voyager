class PolylineEncoder
  constructor: (numLevels, zoomFactor, verySmall, forceEndpoints) ->
    numLevels = 18  unless numLevels
    zoomFactor = 2  unless zoomFactor
    verySmall = 0.00001  unless verySmall
    forceEndpoints = true  unless forceEndpoints
    @numLevels = numLevels
    @zoomFactor = zoomFactor
    @verySmall = verySmall
    @forceEndpoints = forceEndpoints
    @zoomLevelBreaks = new Array(numLevels)

    @zoomLevelBreaks[i] = verySmall * Math.pow(zoomFactor, numLevels - i - 1) for i in [0..numLevels]

  dpEncode: (points) ->
    square = (x) -> x * x
    start = +new Date
    point_count = points.length
    dists = new Array(point_count)
    dists = for point, i in points
      neighbor = if i-1 >= 0 then point[i-1] else point[i+1]
      Math.sqrt(square (point.lat() - neighbor.lat()) + square (point.lon()-neighbor.lon()))
    console.log "dpEncode stack pushes took #{+new Date - start}ms. Ran #{iter} iterations on #{points.length} points."
    encodedPoints = @createEncodings(points, dists)
    encodedLevels = @encodeLevels(points, dists, absMaxDist)
    encodedPoints: encodedPoints
    encodedLevels: encodedLevels
    encodedPointsLiteral: encodedPoints.replace(/\\/g, "\\\\")

  dpEncodeToJSON: (points, color, weight, opacity) ->
    result = undefined
    opacity = 0.9  unless opacity
    weight = 3  unless weight
    color = "#0000ff"  unless color
    result = @dpEncode(points)
    color: color
    weight: weight
    opacity: opacity
    points: result.encodedPoints
    levels: result.encodedLevels
    numLevels: @numLevels
    zoomFactor: @zoomFactor

  dpEncodeToGPolyline: (points, color, weight, opacity) ->
    opacity = 0.9  unless opacity
    weight = 3  unless weight
    color = "#0000ff"  unless color
    new GPolyline.fromEncoded(@dpEncodeToJSON(points, color, weight, opacity))

  dpEncodeToGPolygon: (pointsArray, boundaryColor, boundaryWeight, boundaryOpacity, fillColor, fillOpacity, fill, outline) ->
    i = undefined
    boundaries = undefined
    boundaryColor = "#0000ff"  unless boundaryColor
    boundaryWeight = 3  unless boundaryWeight
    boundaryOpacity = 0.9  unless boundaryOpacity
    fillColor = boundaryColor  unless fillColor
    fillOpacity = boundaryOpacity / 3  unless fillOpacity
    fill = true  if fill is `undefined`
    outline = true  if outline is `undefined`
    boundaries = new Array(0)
    i = 0
    while i < pointsArray.length
      boundaries.push @dpEncodeToJSON(pointsArray[i], boundaryColor, boundaryWeight, boundaryOpacity)
      i++
    new GPolygon.fromEncoded(
      polylines: boundaries
      color: fillColor
      opacity: fillOpacity
      fill: fill
      outline: outline
    )

  distance: (p0, p1, p2, segLength) ->
    u = undefined
    out = undefined
    if p1.lat() is p2.lat() and p1.lng() is p2.lng()
      out = Math.pow(p2.lat() - p0.lat(), 2) + Math.pow(p2.lng() - p0.lng(), 2)
    else
      u = (p0.lat() - p1.lat()) * (p2.lat() - p1.lat()) + (p0.lng() - p1.lng()) * (p2.lng() - p1.lng()) / segLength
      out = Math.pow(p0.lat() - p1.lat(), 2) + Math.pow(p0.lng() - p1.lng(), 2)  if u <= 0
      out = Math.pow(p0.lat() - p2.lat(), 2) + Math.pow(p0.lng() - p2.lng(), 2)  if u >= 1
      out = Math.pow(p0.lat() - p1.lat() - u * (p2.lat() - p1.lat()), 2) + Math.pow(p0.lng() - p1.lng() - u * (p2.lng() - p1.lng()), 2)  if 0 < u and u < 1
    out

  createEncodings: (points, dists) ->
    start = +new Date
    i = undefined
    dlat = undefined
    dlng = undefined
    plat = 0
    plng = 0
    encoded_points = ""
    i = 0
    while i < points.length
      if dists[i] isnt `undefined` or i is 0 or i is points.length - 1
        point = points[i]
        lat = point.lat()
        lng = point.lng()
        late5 = Math.floor(lat * 1e5)
        lnge5 = Math.floor(lng * 1e5)
        dlat = late5 - plat
        dlng = lnge5 - plng
        plat = late5
        plng = lnge5
        encoded_points += @encodeSignedNumber(dlat) + @encodeSignedNumber(dlng)
      i++
    console.log "createEncodings took #{+new Date - start}ms"
    encoded_points

  computeLevel: (dd) ->
    lev = undefined
    if dd > @verySmall
      lev = 0
      lev++  while dd < @zoomLevelBreaks[lev]
      lev

  encodeLevels: (points, dists, absMaxDist) ->
    start = +new Date
    i = undefined
    encoded_levels = ""
    if @forceEndpoints
      encoded_levels += @encodeNumber(@numLevels - 1)
    else
      encoded_levels += @encodeNumber(@numLevels - @computeLevel(absMaxDist) - 1)
    i = 1
    while i < points.length - 1
      encoded_levels += @encodeNumber(@numLevels - @computeLevel(dists[i]) - 1)  unless dists[i] is `undefined`
      i++
    if @forceEndpoints
      encoded_levels += @encodeNumber(@numLevels - 1)
    else
      encoded_levels += @encodeNumber(@numLevels - @computeLevel(absMaxDist) - 1)
    console.log "encodeLevels took #{+new Date - start}ms"

    encoded_levels

  encodeNumber: (num) ->
    encodeString = ""
    nextValue = undefined
    finalValue = undefined
    while num >= 0x20
      nextValue = (0x20 | (num & 0x1f)) + 63
      encodeString += (String.fromCharCode(nextValue))
      num >>= 5
    finalValue = num + 63
    encodeString += (String.fromCharCode(finalValue))
    encodeString

  encodeSignedNumber: (num) ->
    sgn_num = num << 1
    sgn_num = ~(sgn_num)  if num < 0
    @encodeNumber sgn_num

class LatLng
  constructor: (@y, @x) ->
  lat: -> @y
  lng: -> @x

exports.LatLng = LatLng
exports.PolylineEncoder = PolylineEncoder