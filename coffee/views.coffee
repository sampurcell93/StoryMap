$ ->

  window.views = {}
  AllMaps = window.AllMaps

  # The view for a single instance of a map, that is, the full view with controllers, et cetera
  window.views.MapItem = Backbone.View.extend
    tagName: 'section'
    template: $("#map-instance").html()
    initialize: ->
      _.bindAll @, "render", "afterAppend", "toggleMarkers"
      # Two way model view binding
      self = @
      @model.instance = @
      @listenTo @model,
        "loading": @createLoadingOverlay
    render: ->
      @$el.html( _.template @template, @model.toJSON() )
      @
    # Now that the view is in the DOM, do stuff to child elements
    afterAppend: ->
      self = @
      # Instantiate a new google map
      @model.set "map", self.mapObj = new window.GoogleMap @model
      # A function to update the display value of the range
      @articleList = new views.ArticleList collection: @model.get("articles")
      @articleList.render()
      @timeline = new views.Timeline collection: @model.get("articles"), map: @
      @
    toggleMarkers: (markers) ->
      self = @
      _.each markers.outrange, (outlier) ->
        outlier.setMap null
      _.each markers.inrange, (inlier) ->
        unless inlier.getMap()?
          inlier.setMap self.mapObj.map
      @
    events:
      "change .news-search": ->
        @$(".go").trigger "click"
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

  window.views.MapMarker = Backbone.View.extend
    tagName: 'div'
    template: $("#storymarker").html()
    render: ->
      @$el.html(_.template @template, @model.toJSON())
      # Give slight offsets to make sure stories in same location are not overlapped
      @xoff = xOff = Math.random() * 0.1
      @yoff = yOff = Math.random() * 0.1
      # Make the new point
      pt = new google.maps.LatLng(parseInt(@model.get("latitude")) + xOff, parseInt(@model.get("longitude")) + yOff)
      @marker = new google.maps.Marker
        position: pt
        animation: google.maps.Animation.DROP
        title: @model.get "title"
      @

  window.views.Article = Backbone.View.extend
    template: $("#article-item").html()
    tagName: 'li'
    initialize: ->
      _.bindAll @, "render"
    render: ->
      @$el.html(_.template @template, @model.toJSON())
      @
    events:
      "click": ->
        cc @model
  
  window.views.ArticleList = Backbone.View.extend
    el: '.all-articles'
    events: 
      "click": ->
        cc @collection
    initialize: ->
      self = @
      cc @$el
      _.bindAll @, "render", "appendChild"
      @listenTo @collection, "add", (model) ->
        "appending new article"
        self.appendChild model
    appendChild:(model) ->
      view = new views.Article model: model
      @$el.append view.render().el
      @
    render: ->
      console.log "Rendernd model list"
      self = @
      @$el.empty()
      _.each @collection.models, (model) ->
        self.appendChild model
      @

  window.views.Timeline = Backbone.View.extend
    el: 'footer'
    initialize: ->
      self = @
      @map = @options.map
      @min = new Date
      @max = new Date 0
      @speed = 32
      _.bindAll @,  "updateMinMax", "incrementValue", "updateHandles", "play"
      @listenTo @collection, "add", (model) ->
        self.addMarker model
        self.updateMinMax model
        self.updateHandles()
      update_val = (e, ui) ->
        handle = $ ui.handle
        pos = handle.index() - 1
        range  =  ui.values
        # Convert the slider's current value to a readable string
        cleaned = new Date(range[pos]).cleanFormat()
        # Display said string
        display = $("<div/>").addClass("handle-display-value").text cleaned 
        handle.find("div").remove().end().append display
        self.map.toggleMarkers self.collection.filterByDate(ui.values[0], ui.values[1])
      # Make a jquery ui slider element
      @$timeline = @$(".timeline-slider")
      @$timeline.slider
        range: true
        values: [0, 100]
        step: 10000
        slide: update_val
        change: update_val
      @
    render: ->
      self = @
      _.each collection.models, (article) ->
        self.addMarker model
      @
    addMarker: (model) ->
      cc "appending a RED MARKR ONTO TIMELINE"
      view = new views.TimelineMarker model: model
      @$el.append(view.render().el)
      @
    play: ->
      $timeline = @$timeline
      values = $timeline.slider "values"
      lo = values[0]
      hi = values[1]
      @isPlaying = true
      @savedHi = hi
      # get the increment value
      increment = Math.ceil(Math.abs (hi - lo)/300)
      # start the tree
      @incrementValue lo, (@savedHi || hi), increment 
      @
    stop: ->
      @isPlaying = false
      @$(".js-pause-timeline").trigger "switch"
      @
    # Recursive function animates slider to auto play!
    incrementValue: (lo, hi, increment) ->
      self = @
      window.setTimeout ->
        if lo <= hi and self.isPlaying is true
          newlo = lo + increment
          self.$timeline.slider("values", 1, newlo)
          self.incrementValue newlo, hi, increment
        else
          self.stop()
      , @speed
      @
    updateMinMax: (model) ->
      if !model? then return @
      cc "updaing min max"
      date = model.get "date"
      cc "with" + date
      if date < @min
        @min = date
      else if date > @max
        @max = date
      else return @
      @
    updateHandles: ->
      # cache the timeline obj
      $timeline = @$timeline
      # get handles and set their display data to clean dates
      handles = $timeline.find(".ui-slider-handle")
      handles.first().data("display-date", @max.cleanFormat())
      handles.last().data("display-date", @min.cleanFormat())
       # Get the pure millisecond versions of the dates
      mindate = @min.getTime()
      maxdate = @max.getTime()
      # Set the slider values to each end of the spectrum and update the min and max
      $timeline.slider("values", 0, mindate)
      $timeline.slider("values", 1, maxdate)
      $timeline.slider("option", min: mindate, max: maxdate)
      @
    events: 
      "click .js-play-timeline": (e) ->
        $(e.currentTarget).removeClass("js-play-timeline").addClass "js-pause-timeline"
        unless @isPlaying
          @play()
      "click .js-pause-timeline": (e) ->
        $(e.currentTarget).removeClass("js-pause-timeline").addClass "js-play-timeline"
        @stop()
      "switch .js-pause-timeline": (e) ->
        $(e.currentTarget).removeClass("js-pause-timeline").addClass "js-play-timeline"
      "click .js-fast-forward": (e)->
        rel = Math.pow 2, 5 # 32, min speed ratio
        cc rel
        $t = $ e.currentTarget
        speed = @speed
        cc speed
        if speed > 1
          speed /= 2
        else speed = 32
        $t.attr "speed", (rel / speed) + "x"
        @speed = speed
        @



  window.views.TimelineMarker = Backbone.View.extend
    className: '.timeline-marker'
    render: ->



  AllMapsView = new window.views.MapInstanceList({collection: AllMaps})