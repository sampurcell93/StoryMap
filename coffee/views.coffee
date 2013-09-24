$ ->

  window.views = {}
  AllMaps = window.AllMaps

  # The view for a single instance of a map, that is, the full view with controllers, et cetera
  window.views.MapItem = Backbone.View.extend
    tagName: 'section'
    template: $("#map-instance").html()
    initialize: ->
      _.bindAll @, "render", "afterAppend", "updateDateRange", "incrementValue"
      # Two way model view binding
      @model.instance = @
      @listenTo @model,
        "updateDateRange": @updateDateRange
        "loading": @createLoadingOverlay
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
        step: 10000
        slide: update_val
        change: update_val
    updateDateRange: ->
      cc "updating date range"
      articles = @model.get "articles"
      # We want to find the earliest date
      if articles.length > 0
        min = articles.at 0
        max = articles.last()
        # Simple linear min function
        _.each articles.models, (article) ->
          date = article.get("date")
          if date < min.get "date" then min = article
          else if date > max.get "date" then max = article
        # Isolate the date of the articles
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
        # milliseconds in a day
        oneday = 86400000
        # mindate -= oneday
        # maxdate += oneday
        # Set the slider values to each end of the spectrum and update the min and max
        $timeline.slider("values", 0, mindate)
        $timeline.slider("values", 1, maxdate)
        $timeline.slider("option", min: mindate, max: maxdate)
    events:
      "click .go": ->
          self = @
          @model.trigger "loading"
          @model.getGoogleNews @$(".news-search").val(), 0, (query, start, done) ->
             self.model.getYahooNews query, start, (query, start, done) ->
                window.destroyModal()
      "click [data-route]": (e) ->
        $t = $ e.currentTarget
        route = $t.data "route"
        current_route = Backbone.history.fragment
        window.app.navigate route, {trigger: true}
      "click .js-play-timeline": (e) ->
        @playTimeline()
    playTimeline: ->
      $timeline = @$timeline
      values = $timeline.slider "values"
      lo = values[0]
      hi = values[1]
      # get the increment value
      increment = Math.floor(Math.abs (hi - lo)/1000)
      # start the tree
      @incrementValue values[0], values[1] + 86400000, increment 
    # Recursive function animates slider to auto play!
    incrementValue: (lo, hi, increment) ->
      self = @
      window.setTimeout ->
        if lo <= hi
          cc "lo: " + lo
          cc "hi: " + hi
          newlo = lo + increment
          self.$timeline.slider("values", 1, newlo)
          self.incrementValue newlo, hi, increment
      , 4
    # Args: none
    # Rets: this
    # desc: creates a UI overlay so users can't tamper with stuff when it's loading
    createLoadingOverlay: ->
      loader = $("<img/>").addClass("loader").attr("src", "assets/images/loader.gif")
      content = _.template $("#main-loading-message").html(), {}
      window.launchModal $("<div/>").append(content).append(loader), close: false

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