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
# args: an article model
# rets: map obj
window.GoogleMap::plot = (story) ->
  j = story.toJSON()
  # Difference between stuff returned null from DB, or things never set. typeof null = "object"; LOL
  unless !j.lat? or !j.lng? or typeof j.lat == "undefined" or typeof j.lng == "undefined"
    story.set("hasLocation", true)
    # A simple display string
    marker = new views.MapMarker({model: story, map: @map})
    display = marker.render().$el.html()
    marker = marker.marker
    # Push the marker to tha array
    @markers.push marker
    marker.setMap @map
    story.marker = marker
    self = @
    # On click, show data
    google.maps.event.addListener marker, "click", ->
      cc model.toJSON()
      self.infowindow.setContent display
      self.infowindow.open self.map, @
    story.trigger "doneloading"
  @