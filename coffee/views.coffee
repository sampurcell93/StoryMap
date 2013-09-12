$ ->

  window.views = {}
  AllMaps = window.AllMaps

  # The view for a single instance of a map, that is, the full view with controllers, et cetera
  window.views.MapItem = Backbone.View.extend
    tagName: 'section'
    template: $("#map-instance").html()
    initialize: ->
      _.bindAll @, "render"
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
      # Instantiate a new google map
      @model.set "map", new window.GoogleMap @model
      # A function to update the display value of the range
      update_val = (e, ui) ->
          handle = $ ui.handle
          pos = handle.index() - 1
          range  =  ui.values
          display = $("<div/>").addClass("handle-display-value").text(range[pos])
          handle.find("div").remove().end().append display
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
          if date < min.get "date"
            min = article
          else if date > max.get "date"
            max = article
        cc Math.abs max.get "date"
        cc Math.abs min.get "date"
        @$timeline.slider("option", min: min.get("date"), max: max.get("date"))

    events:
      "click .go": ->
        cc @model 
        for start in [0..12] by 4
          cc start
          @model.getGoogleNews @$(".news-search").val(), start
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

  # cache the search bar
  $search = $("#news-search")
  # cache go button
  $go = $("#go")

  $search.focus().on "keydown", (e) ->
    if e.keyCode is 13 or e.which is 13
      $go.trigger "click"
      return
    $(this).data "start_index", $(this).data("start_index") + 1

  window.app.navigate("/map/0", true)