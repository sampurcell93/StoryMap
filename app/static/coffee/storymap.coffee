# Define the map object
# args: optional model
# rets: themap obj
window.GoogleMap =  ->
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
  # get map object - needs fix
  @map = new google.maps.Map(document.getElementById("map-canvas"), @mapOptions)
  @addClusterListeners()
  # Assign an info window handler
  @infowindow = new google.maps.InfoWindow()
  # Link map to parent model if there is one
  # Point markers array to either the model's array, or make a new one.
  @markers = []
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
    @bindEventsOnMarker story.marker
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

window.GoogleMap::bindEventsOnMarker = (markerObj) ->
  display = markerObj.$el.html()
  self = @
  # On click, show data
  google.maps.event.addListener markerObj.marker, "click", ->
    markerObj.model.trigger("showpopup")
    # cc story
    # self.infowindow.setContent display
    # self.infowindow.open self.map, @
  google.maps.event.addListener markerObj.marker, "mouseover", ->
    markerObj.model.trigger("highlight")
  google.maps.event.addListener markerObj.marker, "mouseout", ->
    markerObj.model.trigger("unhighlight")
  @

window.GoogleMap::addClusterListeners = ->
  self = @
  google.maps.event.addListener @map, 'zoom_changed', ->
    zoom =  self.map.getZoom()
    markers = self.markers
    console.log zoom
    if zoom > 6
      _.each markers, (marker) ->
        console.log $(marker.label.labelDiv_)
        $(marker.label.labelDiv_).removeClass("hidden")
        console.log $(marker.label.labelDiv_)
    else 
      _.each markers, (marker) ->
        $(marker.label.labelDiv_).addClass("hidden")