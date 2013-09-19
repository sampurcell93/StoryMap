$ ->

  window.views = {}
  AllMaps = window.AllMaps

  # The view for a single instance of a map, that is, the full view with controllers, et cetera
  window.views.MapItem = Backbone.View.extend
    tagName: 'section'
    template: $("#map-instance").html()
    initialize: ->
      _.bindAll @, "render", "afterAppend", "updateDateRange"
      # Two way model view binding
      @model.instance = @
      @listenTo @model,
        "updateDateRange": @updateDateRange
      @updateDateRange()
    render: ->
      @$el.html( _.template @template, @model.toJSON() )
      @
    # Now that the view is in the DOM, do stuff to child elements
    afterAppend: ->
      self = @
      # Instantiate a new google map
      @model.set "map", new window.GoogleMap @model
      # A function to update the display value of the range
      update_val = (e, ui) ->
          handle = $ ui.handle
          pos = handle.index() - 1
          range  =  ui.values
          # Convert the slider's current value to a readable string
          cleaned = new Date(range[pos]).cleanFormat()
          # Display said string
          display = $("<div/>").addClass("handle-display-value").text cleaned 
          handle.find("div").remove().end().append display
          self.model.filterByDate(ui.values[0], ui.values[1])
      # Make a jquery ui slider element
      @$timeline = @$(".timeline-slider")
      @$timeline.slider
        range: true
        values: [0, 100]
        start: update_val
        change: update_val
        slide: update_val
    updateDateRange: ->
      cc "updating date range"
      articles = @model.get "articles"
      # We want to find the earliest date
      if articles.length > 0
        min = articles.at(0)
        max = articles.last()
        # Simple min function
        _.each articles.models, (article) ->
          date = article.get("date")
          if date < min.get "date" then min = article
          else if date > max.get "date" then max = article
        # Isolate the ate of the articles
        mindate = min.get "date"
        maxdate = max.get "date"
        # cache the timeline obj
        $timeline = @$timeline
        # get handles and set their display data to clean dates
        handles = $timeline.find(".ui-slider-handle")
        handles.first().data("display-date", mindate.cleanFormat())
        handles.last().data("display-date", maxdate.cleanFormat())
        # Get the pure millisecond versions of the dates
        mindate = mindate.getTime()
        maxdate = maxdate.getTime()
        # Set the slider values to each end of the spectrum and update the min and max
        $timeline.slider("values", 0, mindate)
        $timeline.slider("values", 1, maxdate)
        $timeline.slider("option", min: mindate, max: maxdate)


    events:
      "click .go": ->
          @model.getGoogleNews @$(".news-search").val(), 0, @model.getYahooNews
      "click [data-route]": (e) ->
        $t = $ e.currentTarget
        route = $t.data "route"
        current_route = Backbone.history.fragment
        window.app.navigate route, {trigger: true}
  # The view for all instances of saved maps, a list of tabs perhaps
  window.views.MapInstanceList = Backbone.View.extend
    el: ".map-instance-list"
    initialize: ->
      # When the collection is added to, add a new view for the added model
      @listenTo @collection,
        add: @addInstance
      @
    addInstance: (model) ->
      # Create a new view object
      item = new window.views.MapItem model: model
      # Render it, grab its DOM element, and JQueryify it
      instance = $ item.render().el
      # Put it into the list
      instance.appendTo @$el
      item.afterAppend()
      # Hide others, cause this shit is new
      instance.siblings().hide()
      @


  AllMapsView = new window.views.MapInstanceList({collection: AllMaps})
  # AllMaps.add new models.StoryMap()
  window.app.navigate("/map/0", true)