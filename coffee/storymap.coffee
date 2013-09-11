# Define the map object
window.GoogleMap = ( model ) ->
  @mapOptions =
    center: new google.maps.LatLng(0, 0)
    zoom: 2
    mapTypeId: google.maps.MapTypeId.ROADMAP

  map = new google.maps.Map(document.getElementById("map-canvas"), @mapOptions)
  @map = map
  @markers = []
  @infowindow = new google.maps.InfoWindow()
  if model? then @model = model else @model = null
  @

# A function that issues a request to a curl script, retrieving google news stories
window.getGoogleNews = (val, start) ->
  # cc "./getnews.php?q=" + val + "&start=" + start
  $.get "./getnews.php",
    q: val || $search.val()
    start: start
  , (data) ->
    # parse the json
    json = JSON.parse(data)
    if json.responseDetails is "out of range start"
      end = true
      return false
    # Get location data from OpenCalais for each story item
    for i in [0...json.responseData.results.length]
      getCalaisData json.responseData.results[i]
    true

window.getCalaisData = (content) ->
  console.log "getting data"
  # Pass the title and the story body into calais
  context = content.titleNoFormatting + content.content
  $.get "./calais.php",
    content: context
  , (data) ->
    # parse the response object
    json = JSON.parse(data)
    unless json? then return
    console.log(json.doc.info.docDate)
    # Check each property of the returned calais object
    for el of json
      # If it contains a "resolutions" key, it has latitude and longitude
      if json[el].hasOwnProperty("resolutions")
        content.latitude = json[el].resolutions[0].latitude
        content.longitude = json[el].resolutions[0].longitude
        # It's a valid story - push it
        stories.push content
        # Plot the story en el mapa
        StoryMap.plotStory content
        return
  content
window.makeUIDialog = (message) ->
  $(document.body).append("<div class='ui-dialog'>" + message + "</div>").addClass "active-message"
  $(".ui-dialog").hide().fadeIn "fast", ->
    $(this).delay(8000).fadeOut 800, ->
      $(this).remove()
      $(document.body).removeClass "active-message"

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

