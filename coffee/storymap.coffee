# launch modals
window.launchModal =  (content) ->
  modal = $("<div />").addClass("modal")
  if $.isArray(content)
      _.each content, (item) ->
          modal.append(item)
  else modal.html(content)
  modal.prepend("<i class='close-modal icon-untitled-7'></i>")
  $(document.body).addClass("active-modal").append(modal)
  modal

# Define the map object
window.GoogleMap = ( model ) ->
  @mapOptions =
    center: new google.maps.LatLng(0, 0)
    zoom: 2
    mapTypeId: google.maps.MapTypeId.ROADMAP
  cc document.getElementById("map-canvas")
  map = new google.maps.Map(document.getElementById("map-canvas"), @mapOptions)
  @map = map
  @markers = []
  @infowindow = new google.maps.InfoWindow()
  if model? then @model = model else @model = null
  @

window.GoogleMap::plotStory = (story) ->
  xOff = Math.random() * 0.1
  yOff = Math.random() * 0.1
  pt = new google.maps.LatLng(parseInt(story.latitude) + xOff, parseInt(story.longitude) + yOff)
  display_string = "<h3><a target='_blank' href='" + story.unescapedUrl + "'>" + story.title + "</a></h3>" + "<p>" + story.content + "</p>"
  marker = new google.maps.Marker(
    position: pt
    title: story.title
  )
  @markers.push marker
  marker.setMap @map
  that = @
  google.maps.event.addListener marker, "click", ->
    that.infowindow.setContent display_string
    that.infowindow.open that.map, @

