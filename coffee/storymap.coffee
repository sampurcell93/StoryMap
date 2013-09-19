# launch modals
window.launchModal =  (content) ->
  modal = $("<div />").addClass("modal")
  if $.isArray(content)
      _.each content, (item) ->
          modal.append(item)
  else modal.html(content)
  modal.prepend("<i class='close-modal icon-untitled-7'></i>")
  modal.find(".close-modal").on "click", ->
    $(document.body).removeClass("active-modal")
    modal.remove()
  $(document.body).addClass("active-modal").append(modal)
  modal

# Define the map object
window.GoogleMap = ( model ) ->
  # Set default map options
  @mapOptions =
    center: new google.maps.LatLng(0, 0)
    zoom: 2
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
window.GoogleMap::plotStory = (story) ->
  # Give slight offsets to make sure stories in same location are not overlapped
  xOff = Math.random() * 0.1
  yOff = Math.random() * 0.1
  # Make the new point
  pt = new google.maps.LatLng(parseInt(story.latitude) + xOff, parseInt(story.longitude) + yOff)
  # A simple display string
  display_string = "<h3><a target='_blank' href='" + story.unescapedUrl + "'>" + story.title + "</a></h3>" + "<p>" + story.content + "</p>"
  marker = new google.maps.Marker(
    position: pt
    title: story.title
  )
  # Push the marker to tha array
  @markers.push marker
  marker.setMap @map
  that = @
  # On click, show data
  google.maps.event.addListener marker, "click", ->
    cc that.model
    that.infowindow.setContent display_string
    that.infowindow.open that.map, @

