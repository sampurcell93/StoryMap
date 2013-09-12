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
    render: ->
      @$el.html( _.template @template, @model.toJSON() )
      cc @$el.html()
      @
    # Now that the view is in the DOM, do stuff to child elements
    afterAppend: ->
      # Instantiate a new google map
      @model.set "map", new window.GoogleMap @model
      # Make a jquery ui slider element
      @$(".timeline-slider").slider()
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