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
  story = story.toJSON()
  # Give slight offsets to make sure stories in same location are not overlapped
  xOff = Math.random() * 0.1
  yOff = Math.random() * 0.1
  # Make the new point
  pt = new google.maps.LatLng(parseInt(story.latitude) + xOff, parseInt(story.longitude) + yOff)
  # A simple display string
  display_string = "<h3><a target='_blank' href='" + story.unescapedUrl + "'>" + story.title + "</a></h3>" + "<p>" + story.content + "</p>"
  marker = new google.maps.Marker(
    position: pt
    animation: google.maps.Animation.DROP
    title: story.title
  )
  # Push the marker to tha array
  @markers.push marker
  marker.setMap @map
  articleModel.set "marker", marker
  that = @
  # On click, show data
  google.maps.event.addListener marker, "click", ->
    cc that.model
    that.infowindow.setContent display_string
    that.infowindow.open that.map, @
  @