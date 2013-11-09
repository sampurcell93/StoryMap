$ ->
  blueIcon = "/static/images/bluepoi.png"
  redIcon = "/static/images/redpoi.png"

  # img = document.createElement("img")
  # img.src = blueIcon
  # img.addEventListener("load", ->
  #   cc "ld"
  #   document.body.appendChild img
  # )

  window.views = {}

  # The view for a single instance of a map, that is, the full view with controllers, et cetera
  window.views.MapItem = Backbone.View.extend
    tagName: 'section'
    template: $("#map-instance").html()
    initialize: ->
      _.bindAll @, "render", "afterAppend", "toggleMarkers", "search"
      # Two way model view binding
      self = @
      @model.instance = @
      @listenTo @model,
        "loading": @createLoadingOverlay
        "doneloading": ->
          window.destroyModal()
    render: ->
      self = @
      @$el.html( _.template @template, @model.toJSON() )
      Underscore = 
                compile: (template) ->
                    compiled = _.template(template)
                    render: (context) -> 
                        compiled(context)
      @model.get("existingQueries").fetch success: (coll) ->
        cc coll.models
        self.$(".js-news-search").typeahead([
          {
              name: 'Queries'
              template: $("#existing-query-item").html()
              local: coll.models
              engine: Underscore
              limit: 1000
          }
          ])
      @
    # Now that the view is in the DOM, do stuff to child elements
    afterAppend: ->
      self = @
      # Instantiate a new google map
      @model.set "map", self.mapObj = new window.GoogleMap @model
      # A function to update the display value of the range
      @articleList = new views.ArticleList collection: @model.get("articles"), map :@
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
    search: (query) ->
      self = @
      map = @model
      map.trigger "loading"
      # When done with getting news, stop the loading 
      map.getYahooNews(query).getGoogleNews query, 0, () ->
        window.destroyModal()
        _.each map.get("articles").models, (article) ->
          console.log(article.toJSON())
          article.getCalaisData()

    events:
      "keydown .js-news-search": (e) ->
        key = e.keyCode || e.which
        val = $(e.currentTarget).val()
        if key == 13 then @model.checkExistingQuery(val, @search)
      "click .go": (e) ->
        @model.checkExistingQuery( @$(".js-news-search").val() , @search)
      "click [data-route]": (e) ->
        $t = $ e.currentTarget
        route = $t.data "route"
        current_route = Backbone.history.fragment
        window.app.navigate route, {trigger: true}
      "click .js-save-query": ->
        cc "saving"

    # Args: none
    # Rets: this
    # desc: creates a UI overlay so users can't tamper with stuff when it's loading
    createLoadingOverlay: ->
      content = _.template $("#main-loading-message").html(), {}
      window.launchModal $("<div/>").append(content), close: false
      @
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
    initialize: ->
      @map = @options.map || window.map
      @listenTo @model,
        "hide": ->
          if @marker?
            @marker.setMap null
        "show": ->
          if @marker?
            @marker.setMap @map
        "highlight": ->
          if @marker?
            @marker.setIcon blueIcon
        "unhighlight": ->
          if @marker?
            @marker.setIcon redIcon

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
        icon: redIcon
      @

  window.views.ArticleListItem = Backbone.View.extend 
    template: $("#article-item").html()
    tagName: 'li'
    initialize: ->
      _.bindAll @, "render"
      self = @
      @listenTo @model, 
        "hide": ->
          console.log("hiding")
          this.$el.hide()
        "show": ->
          console.log("showing")
          this.$el.show()
        "loading": ->
          cc "loading"
          self.$el.prepend("<img class='loader' src='static/images/loader.gif' />")
        "change:hasLocation": -> 
            @$el.addClass("has-location")
    render: ->
      @$el.append(_.template @template, @model.toJSON())
      @
    events:
      "click": ->
        cc @model.toJSON()
      "mouseover": ->
        @model.trigger("highlight")
      "mouseout": ->
        @model.trigger("unhighlight")

  
  # List of articles, regardless of location data, and controls for filtering
  window.views.ArticleList = Backbone.View.extend
    el: '.all-articles'
    list: 'ol.article-list'
    sortopts: '.sort-options-list'
    hidden: false
    events: 
      "click": ->
        cc @collection
    initialize: ->
      self = @
      @map = @options.map
      _.bindAll @, "render", "appendChild", "toggle", "filter"
      @listenTo @collection, "add", (model) ->
        self.appendChild model
    appendChild:(model) ->
      view = new views.ArticleListItem model: model
      @$(@list).find(".placeholder").remove().end().append view.render().el
      @
    render: ->
      self = @
      @$(@list).empty()
      _.each @collection.models, (model) ->
        self.appendChild model
      @;
    filter: (query) ->
      _.each @collection.models, (article) -> 
        str = (article.toJSON().title + article.toJSON().content).toLowerCase()
        if str.indexOf(query.toLowerCase()) == -1
          article.trigger "hide"
        else 
          article.trigger "show"
    toggle: ->
      this.hidden = !this.hidden
      @$el.toggleClass "away"
      map = @map.mapObj.map
      startTime = new Date().getTime()
      # We want the map to smoothly enlarge, so we need to 
      # trigger a resize at each stage of the UI transition
      smoothRender = setInterval ->
        timeFromStart = new Date().getTime() - startTime
        google.maps.event.trigger map, 'resize'
        map.setZoom map.getZoom()
        # transition lasts .34sec
        if timeFromStart >= 450
          clearInterval smoothRender
      , 1
    events: 
      "keyup .js-filter-articles": (e) ->
        val = ($t = $(e.currentTarget)).val()
        @filter val
      "click .js-toggle-view": "toggle"
      "click .placeholder": ->
        @map.$(".js-news-search").focus()
      'click .js-sort-options': (e) ->
        @$(@sortopts).toggle("fast")
        e.stopPropagation()
        e.preventDefault()
      'click .js-filter-param': (e) ->
        $t = $ e.currentTarget
        show = $t.data "filtered"
        if typeof show == "undefined" then show = true
        $t.data "filtered", !show
        cc($t.data "filtered")
      'click .js-sort-param': (e) ->
        $t = $ e.currentTarget
        $siblings = $t.siblings(".js-sort-param")


  window.views.Timeline = Backbone.View.extend
    el: 'footer'
    speeds: { forward : 32, back : 32 }
    dir: "forward"
    min: new Date
    max: new Date 0
    initialize: ->
      self = @
      @map = @options.map
      _.bindAll @,  "updateMinMax", "changeValue", "updateHandles", "play"
      @listenTo @collection, "add", (model) ->
        self.updateMinMax model
        self.updateHandles()
      # callback to run each time the timeline is changed
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
      _.each @collection.models, (article) ->
        if article.get("latitude")? and article.get("longitude")?
          self.addMarker article
      @
    addMarker: (model) ->
      cc "appending a RED MARKR ONTO TIMELINE"
      # Get the article's position in the range 
      pos = model.get("date").getTime()
      # Calculate a percentage for the article and pass into marker view
      view = new views.TimelineMarker model: model, left: pos/@max
      @$(".slider-wrap").append(view.render().el)
      @
    play: ->
      $timeline = @$timeline
      values = $timeline.slider "values"
      lo = values[0]
      hi = values[1]
      @isPlaying = true
      dir = if @dir == "forward" then 1 else -1
      # start the tree
      inc = dir*Math.ceil(Math.abs (hi - lo)/300)
      cc @speeds[@dir]
      @changeValue lo, hi, inc, (lo, hi) ->
        lo <= hi
      @
    stop: ->
      @isPlaying = false
      @$(".js-pause-timeline").trigger "switch"
      @
    # Recursive function animates slider to auto play!
    changeValue: (lo, hi, increment, comparator) ->
      self = @
      window.setTimeout ->
        if comparator(lo, hi) is true and self.isPlaying is true
          newlo = lo + increment
          self.$timeline.slider("values", 1, newlo)
          self.changeValue newlo, hi, increment, comparator
        else
          self.stop()
      , @speeds[@dir]
      @
    updateMinMax: (model) ->
      if !model? then return @
      cc "updating min max"
      date = model.get "date"
      if date < @min
        @min = date
      if date > @max
        @max = date
      @
    updateHandles: ->
      cc "updating handles"
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
    setSpeed: (dir) ->
        rel = Math.pow 2, 5 # 32, min speed ratio
        speed = @speeds[dir]
        if speed > 1
          speed /= 2
        else speed = 32
        @speeds[dir] = speed
        @dir = dir
        rel / speed
    renderSpeed: (e)->
      if e?
        $t = $ e.currentTarget
        speed = @setSpeed($t.attr "dir" || "forward")
        $t.attr "speed", speed + "x"
        $t.addClass("selected").siblings(".js-speed-control").removeClass "selected"
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
      "click .js-fast-forward": "renderSpeed"
      "click .js-rewind": "renderSpeed"
      "mouseover .timeline-controls li": (e) ->
        $t = $ e.currentTarget


  window.views.TimelineMarker = Backbone.View.extend
    className: 'timeline-marker'
    render: ->
      num = @options.left || (Math.random() * 100)
      console.log "putting marker at " + num
      @$el.css('left', (num*100) + "%")
      @