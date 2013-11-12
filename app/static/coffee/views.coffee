$ ->

  blueIcon = "/static/images/bluepoi.png"
  redIcon = "/static/images/redpoi.png"

  window.views = {}

  # The view for a single instance of a map, that is, the full view with controllers, et cetera
  window.views.MapItem = Backbone.View.extend
    el: 'section.map'
    typeahead: false
    url: -> '/favorite?user_id=' + @model.user.id + "&query_id=" + @currQuery.id
    initialize: ->
      _.bindAll @, "render", "toggleMarkers", "search"
      # Two way model view binding
      self = @
      @model.instance = @
      @on
        "loading": @createLoadingOverlay
        "doneloading": ->
          window.destroyModal()
      @listenTo @model, "change:title", (model, title) ->
        self.$(".js-news-search").typeahead('setQuery', title)
      window.mapObj = self.mapObj = @model.get("map")
      $searchbar = self.$(".js-news-search")
      if !@typeahead
        Underscore = 
                  compile: (template) ->
                      compiled = _.template(template)
                      render: (context) -> 
                          compiled(context)
        $searchbar.typeahead([
          {
              name: 'Queries'
              template: $("#existing-query-item").html()
              local: window.existingQueries.models
              engine: Underscore
              limit: 1000
          }
          ])
        @typeahead = true
      @storyList = new views.StoryList collection: @model.get("stories"), map :@
      @timeline = new views.Timeline collection: @model.get("stories"), map: @
      @render()
      @
    render: ->
      @$(".js-news-search").typeahead('setQuery', @model.get("title") || "")
      @renderComponents()
      @plotAll()
    plotAll: ->
      _.each @model.get("stories").models, (story) ->
        story.plot()
      @
    renderComponents: ->
      if @storyList? then @storyList.render()
      # if @timeline? then @timeline.render()
      @
    toggleMarkers: (markers) ->
      self = @
      _.each markers.outrange, (outlier) ->
        outlier.setMap null
      _.each markers.inrange, (inlier) ->
        unless inlier.getMap()?
          inlier.setMap self.mapObj.map
      @
    # accepts a query model and saves it in a global object
    cacheQuery: (query) ->
      existingQueries._byTitle[query.get("title")] = query
      @
    search: (query) ->
      @$(".icon-in").css("visibility", "visible")
      # @loadQuery new models.Query({title: query})
      self = @
      # window.mapObj.clear()
      queryobj = new models.Query({title: query})
      @model = queryobj
      @storyList.collection = @timeline.collection = queryobj.get("stories")
      @storyList.bindListeners()
      @cacheQuery queryobj
      @trigger "loading"
      # pass in a function for how to handle a new query, and one for an existing query
      queryobj.exists(
        ((query) ->
          queryobj.getGoogleNews query, 0, () ->
            window.destroyModal()
            console.log queryobj
            _.each queryobj.get("stories").models, (story) ->
              story.getCalaisData()
        ), 
        ((model) ->
          _.extend queryobj.attributes, model.attributes
          window.existingQueries.add queryobj
          self.loadQuery queryobj
        ) 
      )
    # Expects a models.Query, loads and renders it if it exists, needs an id
    loadQuery: (query) ->
      model = query || @model
      self = @
      model.fetch 
        success: (model, resp, options) ->
          window.mapObj.clear()
          formatted = model.attributes
          formatted.stories = new collections.Stories(resp["stories"].models)
          self.model = query
          self.storyList.collection = self.timeline.collection = formatted.stories
          self.render()
          destroyModal()
        error: ->
    events:
      "keydown .js-news-search": (e) ->
        key = e.keyCode || e.which
        val = $(e.currentTarget).val()
        if key == 13 then @search val
      "click .go": (e) ->
        @search @$(".js-news-search").val()
      "click [data-route]": (e) ->
        $t = $ e.currentTarget
        route = $t.data "route"
        current_route = Backbone.history.fragment
        window.app.navigate route, {trigger: true}
      "click .js-save-query": (e) ->  
        toSave = @model
        console.log toSave
        stories = toSave.get("stories")
        # # There should be no distinction between saving and favoriting to the user - clicking save does both
        toSave.save null, 
          success: (resp,b, c) ->
            toSave.favorite()
            toSave.set("stories", stories)
            _.each stories.models, (story) ->
              story.set("query_id", toSave.id)
              story.save(null, {
                success: (model, resp) ->
                  cc resp
                error: (model, resp) ->
                  cc resp
              })
            error: ->
              cc "YOLo"

    # Args: none
    # Rets: this
    # desc: creates a UI overlay so users can't tamper with stuff when it's loading
    createLoadingOverlay: ->
      content = _.template $("#main-loading-message").html(), {}
      window.launchModal $("<div/>").append(content), close: false
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
      pt = new google.maps.LatLng(parseInt(@model.get("lat")) + xOff, parseInt(@model.get("lng")) + yOff)
      console.log pt
      @marker = new google.maps.Marker
        position: pt
        animation: google.maps.Animation.DROP
        title: @model.get "title"
        icon: redIcon
        map: window.mapObj.map
      @

  window.views.StoryListItem = Backbone.View.extend 
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
          cc  "setting loaction"
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
  window.views.StoryList = Backbone.View.extend
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
      @bindListeners()
    bindListeners: ->
      console.log "binding listeners"
      console.log @collection
      self = @
      @listenTo @collection, "add", (model) ->
        self.appendChild model
    appendChild:(model) ->
      view = new views.StoryListItem model: model
      @$(@list).find(".placeholder").remove().end().append view.render().el
      @
    render: ->
      self = @
      @$(@list).children().not(".placeholder").remove()
      console.log @collection
      _.each @collection.models, (model) ->
        self.appendChild model
      @;
    filter: (query) ->
      _.each @collection.models, (story) -> 
        str = (story.toJSON().title + story.toJSON().content).toLowerCase()
        if str.indexOf(query.toLowerCase()) == -1
          story.trigger "hide"
        else 
          story.trigger "show"
    toggle: ->
      cc "Toggling"
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
    initialize: ->
      self = @
      @map = @options.map
      _.bindAll @, "render", "addMarker", "changeValue", "play", "stop", "updateHandles"
      # @listenTo @collection, "add", (model) ->
        # self.updateMinMax model
        # self.updateHandles()
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
      _.each @collection.models, (story) ->
        if story.get("lat")? and story.get("lng")?
          self.addMarker story
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
      @updateHandles()
      values = @$timeline.slider "values"
      lo = values[0]
      hi = values[1]
      console.log values
      @isPlaying = true
      dir = if @dir == "forward" then 1 else 1
      # start the tree
      inc = dir*Math.ceil(Math.abs (hi - lo) / 300)
      console.log inc
      @changeValue lo, hi, inc, (locmp, hicmp) ->
        locmp <= hicmp
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
    # should only need to call once per session
    updateHandles: ->
      if @max? and @min? then return
      prevcomparator = @collection.comparator
      @collection.comparator = (model) ->
        return model.get("date")
      @collection.sort()
      @min = min = @collection.first().get("date")
      @max = max = @collection.last().get("date")
      mindate = parseInt(min.getTime())
      maxdate = parseInt(max.getTime())
      # cache the timeline obj
      $timeline = @$timeline
      # get handles and set their display data to clean dates
      handles = $timeline.find(".ui-slider-handle")
      handles.first().data("display-date", min.cleanFormat())
      handles.last().data("display-date", max.cleanFormat())
      # Set the slider values to each end of the spectrum and update the min and max
      $timeline.slider("option", min: mindate, max: maxdate)
      $timeline.slider("values", 0, mindate)
      $timeline.slider("values", 1, maxdate)
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

  ( ->
    i = 0
    randClasses = ["blueribbon", "green", "orangestuff", "pink", "purple", "tendrils"]
    window.views.QueryThumb = Backbone.View.extend
      tagName: 'li'
      template: $("#query-thumb").html()
      searchComplete: ->
        console.log arguments
      render: ->
        @$el.html(_.template @template, @model.toJSON()).addClass(randClasses[i++ % 6])
        @
      events: 
        "click .js-load-map": ->
          window.app.navigate("/query/" + @model.get("title"), true)
  )()

  window.views.QueryThumbList = Backbone.View.extend
    tagName: 'ul'
    className: 'query-thumb-list'
    template: $("#query-list-help").html()
    appendChild: (model) ->
      thumb = new views.QueryThumb model: model
      @$el.append thumb.render().el
      @
    render: ->
      self = @
      @$el.html(_.template @template, {})
      _.each @collection.models, (query) ->
        self.appendChild query
      @
