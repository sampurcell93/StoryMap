# Define the map object
# args: optional model
# rets: themap obj
window.GoogleMap = ( model ) ->
  # Set default map options
  @mapOptions =
    center: new google.maps.LatLng(35, -62)
    zoom: 3
    mapTypeId: google.maps.MapTypeId.ROADMAP
  # get map object - needs fix
  @map = new google.maps.Map(document.getElementById("map-canvas"), @mapOptions)
  # Assign an info window handler
  @infowindow = new google.maps.InfoWindow()
  # Link map to parent model if there is one
  @model = model || null
  # Point markers array to either the model's array, or make a new one.
  @markers = model.get("markers") || []
  @

# Plot a single story on the map
# args: an article model
# rets: map obj
window.GoogleMap::plotStory = (story) ->
  articleModel = story
  # A simple display string
  marker = new views.MapMarker model: story
  marker = marker.render().marker
  display = marker.el
  # Push the marker to tha array
  @markers.push marker
  marker.setMap @map
  articleModel.set "marker", marker
  that = @
  # On click, show data
  google.maps.event.addListener marker, "click", ->
    cc that.model
    that.infowindow.setContent display
    that.infowindow.open that.map, @
  @