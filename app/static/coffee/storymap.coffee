# Define the map object
# args: optional model
# rets: themap obj
window.GoogleMap = ( @model ) ->
  # Set default map options
  @mapOptions =
    center: new google.maps.LatLng(35, -62)
    zoom: 2
    styles: themes[window.user.mapStyle] || themes['gMapRetro']
    mapTypeControl: false
    mapTypeId: google.maps.MapTypeId.ROADMAP
    zoomControlOptions: 
      position: google.maps.ControlPosition.LEFT_CENTER
    panControlOptions:
      position: google.maps.ControlPosition.LEFT_CENTER
    # disableDefaultUI: true,
  # get map object - needs fix
  @map = new google.maps.Map(document.getElementById("map-canvas"), @mapOptions)
  # Assign an info window handler
  @infowindow = new google.maps.InfoWindow()
  # Link map to parent model if there is one
  # Point markers array to either the model's array, or make a new one.
  @markers = @model.get("markers") || []
  @

# Plot a single story on the map
# args: an story model
# rets: map obj
window.GoogleMap::plot = (story) ->
  j = story.toJSON()
  # Difference between stuff returned null from DB, or things never set. typeof null = "object"; LOL
  unless !j.lat? or !j.lng? or typeof j.lat == "undefined" or typeof j.lng == "undefined"
    story.marker = new views.MapMarker({model: story, map: @map}).render()
    markerIcon = story.marker.marker
    @bindEvents story.marker
    markerIcon.setMap @map
    @markers.push markerIcon
    self = @
    story.set("hasLocation", true)
  else 
    story.set("hasLocation", false)
  story.trigger "doneloading"
  @

window.GoogleMap::clear = ->
  _.each @markers, (marker) ->
    marker.setMap null
  @

window.GoogleMap::bindEvents = (markerObj) ->
  display = markerObj.$el.html()
  self = @
  # On click, show data
  google.maps.event.addListener markerObj.marker, "click", ->
    # cc story
    self.infowindow.setContent display
    self.infowindow.open self.map, @
  google.maps.event.addListener markerObj.marker, "mouseover", ->
    markerObj.model.trigger("highlight")
  google.maps.event.addListener markerObj.marker, "mouseout", ->
    markerObj.model.trigger("unhighlight")
  @