$ ->

  blueIcon = "static/images/bluepoi.png"
  redIcon = "static/images/redpoi.png"

  window.views = {}

  # The view for a single instance of a map, that is, the full view with controllers, et cetera
  window.views.MapItem = Backbone.View.extend
    el: 'section.map'
    typeahead: false
    url: -> './favorite?user_id=' + @model.user.id + "&query_id=" + @currQuery.id
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
      window.mapObj = self.mapObj = @model.map
      $searchbar = self.$(".js-news-search")
      if !@typeahead
        Underscore = 
                  compile: (template) ->
                      compiled = _.template(template)
                      render: (context) -> 
                          compiled(context)
        # Get all queries then set the local array as a 
        # pointer for the autocomplete module
        $.get "./queries", {}, (response) =>
          _.each response.queries, (r) ->
            r.value = r.title
            r.tokens = [r.title]

          $searchbar.typeahead([
            {
                name: 'Queries'
                template: $("#existing-query-item").html()
                local: response.queries
                engine: Underscore
                limit: 1000
            }
            ])
          @typeahead = true
      @timeline = new views.Timeline collection: @model.get("stories"), map: @
      @storyList = new views.StoryList collection: @model.get("stories"), map :@, timeline: @timeline
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
      if @timeline?
        @timeline.reset().updateHandles(true).render()
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
      @timeline.reset().render()
      @storyList.bindListeners()
      @cacheQuery queryobj
      @trigger "loading"
      mapObj.clear()
      # pass in a function for how to handle a new query, and one for an existing query
      queryobj.exists(
        ((model) ->
          app.navigate("query/" + model, true)
        ),
        ((query) =>
          queryobj.getGoogleNews 0, 
            (queryobj.getFeedZilla(
              (queryobj.getYahooNews 0, =>
                window.destroyModal()
                window.existingQueries.add queryobj
                @timeline.reset().updateHandles(true).render()
                queryobj.analyze =>
                  $(".js-save-query").removeClass("hidden")
              )  
            ) 
            )
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
          formatted.stories = new collections.Stories(resp["stories"].models, {parse: true})
          self.model = query
          self.storyList.collection = self.timeline.collection = formatted.stories
          self.render()
          destroyModal()
        error: ->
    events:
      "click .js-toggle-analytics": (e) ->
        cc "analytics on the way thoooo"
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
        # console.log toSave
        stories = toSave.get("stories")
        # # There should be no distinction between saving and favoriting to the user - clicking save does both
        toSave.save null, 
          success: (resp,b, c) ->
            toSave.favorite()
            len = stories.length
            _.each stories.models, (story, i) ->
              story.set("query_id", toSave.id)
            debugger
            $.post "./stories/many", {models: stories.toJSON()}, ->
                console.log(arguments);
                debugger
            , 'json'
            error: ->
              cc "Something went wrong when saving the stories"

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
      _.bindAll @, "render"
      @listenTo @model,
        "hide": ->
          if @marker?
            @marker.setMap null
        "show": ->
          if @marker?
            @marker.setMap @map
            # @marker.setzIndex(google.maps.Marker.MAX_ZINDEX + 1)
        "highlight": ->
          if @marker?
            @marker.setIcon blueIcon
        "unhighlight": ->
          if @marker?
            @marker.setIcon redIcon
        "showpopup": ->
          if @marker? and @map.getZoom() >= 7
            @map.setCenter @marker.getPosition()
        "center": ->
          if @marker?
            @map.setCenter @marker.getPosition()

    render: ->
      @$el.html(_.template @template, @model.toJSON())
      # Give slight offsets to make sure stories in same location are not overlapped
      @xoff = xOff = Math.random() * 0.1
      @yoff = yOff = Math.random() * 0.1
      # Make the new point
      pt = new google.maps.LatLng(parseFloat(@model.get("lat")) + xOff, parseFloat(@model.get("lng")) + yOff)
      @marker = new MarkerWithLabel
        position: pt
        animation: google.maps.Animation.DROP
        title: @model.get "title"
        icon: redIcon
        map: window.mapObj.map
        labelContent: @model.get("date").cleanFormat()
        labelClass: 'map-label hidden'
        labelAnchor: new google.maps.Point(32, 0)
      @

  window.views.QuickStory = Backbone.View.extend
    template: $("#quick-story-popup").html()
    className: 'quick-story'
    tagName: 'dl'
    render: ->
      @$el.html(_.template(@template, @model.toJSON()))
      @
    events:
      click: ->
        @model.trigger "center"


  # View for a single story item, exposed to the global machine (sigh)
  window.views.StoryListItem = ( ->
    GeoItem = Backbone.View.extend
        tagName: 'li'
        template: $("#geocode-choice").html()
        initialize: (attrs)->
          _.extend @, attrs
          @
        render: ->
          #  not a model, just a plain obj
          @$el.html(_.template @template, @bareobj)
          @
        events: 
          click: ->
            cc @story
            cc @bareobj
            if @story
              geo = @bareobj.geometry.location
              @story.save {
                lat: geo.lat,
                lng: geo.lng,
                location: @bareobj.formatted_address
              }, success: (response) =>
                  @$el.addClass("icon-location-arrow")
                  setTimeout =>
                    destroyModal()
                    @story.set "hasLocation", true
                    @story.plot()
                  , 1400


    GeoList = Backbone.View.extend
        el: "ul.geocode-choices"
        initialize: (attrs) ->
          _.bindAll @, "render", "append" 
          _.extend @, attrs
          @render()
          @
        append: (loc) ->
          if !loc.geometry? then return @
          item = new GeoItem({bareobj: loc, story: @story})
          @$el.append item.render().el
          @
        render: ->
          s = if @locs.length == 1 then "" else "s"
          @$el.html("<li class='geo-header'>We found " + @locs.length + " possible location" + s + "</li>")
          _.each @locs, @append
          @

    Backbone.View.extend 
      template: $("#article-item").html()
      tagName: 'li'
      enterLocTemplate: $("#enter-loc").html()
      initialize: (attrs) ->
        @popup = new views.QuickStory model: @model
        _.bindAll @, "render", "getPosition", "togglePopup"
        _.extend @, attrs
        self = @
        @listenTo @model,
          "save" : ->
            cc "SAVED THIS BITCH"
          "hide": ->
            console.log("hiding")
            this.$el.hide()
          "show": ->
            console.log("showing")
            this.$el.show()
          "loading": ->
            @$el.addClass("loading")
          "change:hasLocation": (model, hasLocation)->
            if hasLocation then @$el.removeClass("no-location").addClass("has-location")
            else @$el.removeClass("has-location").addClass("no-location")
          "doneloading": ->
          "highlight": ->
            @$el.addClass("highlighted")
          "unhighlight": ->
            @$el.removeClass("highlighted")
          "showpopup": @togglePopup
      launchLocationPicker: ->
        iface = _.template @enterLocTemplate, {title: @model.escape("title").stripHTML()}
        iface = launchModal iface
        getLocs = =>
          loader = $("<p/>").addClass("center loading-geocode-text").text("Loading.....")
          iface.append loader
          @model.geocode iface.find(".js-address-value").val(), 
            success: (coords) =>
              list = new GeoList locs: coords, story: @model
              loader.remove()
            error: =>
                loader.remove()
                setTimeout window.destroyModal, 1500

        iface.find(".js-address-value").focus().on "keydown", (e) =>
          key = e.keyCode || e.which
          if key is 13 then getLocs()
        iface.find(".js-geocode-go").on "click", =>
          getLocs()
      getPosition: ->
        @$el.position().top
      togglePopup: ->
        self = @
        @popup.render()
        $(".quick-story").not(@popup.el).slideUp "fast"
        @popup.$el.slideToggle "fast", ->
          $parent = self.$el.parent("ol")
          pos = self.getPosition() + $parent.scrollTop() - 100
          $parent.animate({ scrollTop: pos }, 300);
      render: ->
        if @model.hasLocation()
            @$el.addClass("has-location")
        else 
            @$el.addClass("no-location")
        @$el.append(_.template @template, @model.toJSON())
        @$el.append $(@popup.render().el).hide()
        @
      events:
        "dblclick .article-title":  ->  
          w = window.open(@model.get("url"), "_blank")
          w.focus()
        "click .article-title": (e) ->
            @togglePopup(e)
        "mouseover": ->
          @model.trigger("highlight")
        "mouseout": ->
          @model.trigger("unhighlight")
        "click .js-set-location": "launchLocationPicker"
        "click .js-show-model": "togglePopup"
        "click .js-zoom-to-date": ->
          @timeline.zoomTo(@model.get("date"))
  )()
    
  # List of articles, regardless of location data, and controls for filtering
  window.views.StoryList = Backbone.View.extend
    el: '.all-articles'
    list: 'ol.article-list'
    sortopts: '.sort-options-list'
    hidden: false
    events: 
      "click": ->
        cc @collection
    initialize: (attrs) ->
      self = @
      @map = @options.map
      _.extend @, attrs
      _.bindAll @, "render", "appendChild", "toggle", "filter"
      @bindListeners()
    bindListeners: ->
      self = @
      @render()
      @listenTo @collection, "add", (model) ->
        self.appendChild model
    appendChild:(model) ->
      console.log model.get("title")
      view = new views.StoryListItem model: model, timeline: @timeline
      @$(@list).find(".placeholder").remove().end().append view.render().el
      @
    render: ->
      self = @
      @$(@list).children().not(".placeholder").remove()
      _.each @collection.models, (model) ->
        self.appendChild model
      @;
    filterFns:  
      "location":(story) ->  story.get("lat") != null and story.get("lng") != null
      "nolocation":(story) -> story.get("lat") == null and story.get("lng") == null
      "favorite":(story) -> false
      "google":(story) -> story.get("aggregator") == "google"
      "yahoo":(story) -> story.get("aggregator") == "yahoo"
    filter: (param, show, closure) ->
      filterFn = @filterFns[param]
      _.each @collection.models, (story) -> 
        filter = filterFn(story, closure)
        if filter and show == false
          story.trigger("hide")
          story.filteredout = true
        else if filter and show == true
          story.trigger("show")
          story.filteredout = false
      @
    sortFns: 
      "newest": (model) -> -model.get("date")
      "oldest": (model) -> model.get("date")
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
        # transition lasts .45sec
        if timeFromStart >= 450
          clearInterval smoothRender
      , 3
    events: 
      "keyup .js-filter-articles": (e) ->
        val = ($t = $(e.currentTarget)).val().toLowerCase()
        _.each @collection.models, (story) ->
          if story.get("title").toLowerCase().indexOf(val) != -1 and !story.filteredout
            story.trigger("show")
          else story.trigger "hide"
      "click .js-toggle-view": "toggle"
      "click .placeholder": ->
        @map.$(".js-news-search").focus()
      'click .js-sort-options': (e) ->
        @$(@sortopts).toggle("fast")
        e.stopPropagation()
        e.preventDefault()
      'click .js-filter-param': (e) ->
        $t = $ e.currentTarget
        show = $t.data "showing"
        if typeof show == "undefined" then show = false
        $t.data "showing", !show
        @filter $t.data("param"), !$t.data("showing")
      'click .js-sort': (e) ->
        $t = $ e.currentTarget
        $t.addClass("active")
        $siblings = $t.siblings(".active")
        $siblings.each(->$(@).trigger("switch"))
        @collection.comparator = @sortFns[$t.data("sort")]
        @collection.sort()
        @render()


  window.views.QueryThumb = (->
    i = 0
    randClasses = ["blueribbon", "green", "orangestuff", "pink", "purple", "angle"]
    Backbone.View.extend
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
