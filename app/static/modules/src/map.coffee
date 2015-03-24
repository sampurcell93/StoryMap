define ["hub", "themes", "stories"], (hub, themes, stories) ->
    dispatcher = hub.dispatcher

    blueIcon = "static/images/bluepoi.png"
    redIcon = "static/images/redpoi.png"


    class MapMarker extends Backbone.View
        tagName: 'div'
        template: _.template($("#storymarker").html())
        initialize: (attrs)->
            @map = attrs.map
            _.bindAll @, "render"
            @listenTo @model,
                "hide": ->
                    console.log("hiding")
                    if @icon? and @icon.getMap()?
                        @icon.setMap null
                "show": ->
                    if @icon? and !@icon.getMap()?
                        @icon.setMap @map
                    # @icon.setzIndex(google.maps.Marker.MAX_ZINDEX + 1)
                "highlight": (bounce=true) ->
                    if @icon?
                        @icon.setIcon blueIcon
                        @icon.setZIndex(100);
                        if bounce is true
                            @bounceMarker()
                "unhighlight": (stopBouncing=true) ->
                    if @icon?
                        @icon.setIcon redIcon
                        @icon.setZIndex(1);
                        if stopBouncing is true
                            @stopBouncingMarker()

                "showpopup": ->
                    if @icon? and @map.getZoom() >= 7
                        @map.setCenter @icon.getPosition()
                "center": ->
                    if @icon?
                        @map.setCenter @icon.getPosition()
        bounceMarker: ->
            @mouseentertime = new Date().getTime();
            @icon.setAnimation(google.maps.Animation.BOUNCE)
            if @mouseleavetimeout
                clearTimeout(@mouseleavetimeout)
        stopBouncingMarker: ->
            now = new Date().getTime();
            bounce_diff = (now - @mouseentertime) % 700;
            @icon.setZIndex(1);
            @mouseleavetimeout = setTimeout =>
                    @icon.setAnimation(null)
            , 700 - bounce_diff
        render: ->
            @$el.html(@template(@model.toJSON()))
            # Give slight offsets to make sure stories in same location are not overlapped
            @xoff = xOff = Math.random() * 0.1
            @yoff = yOff = Math.random() * 0.1
            # Make the new point
            pt = new google.maps.LatLng(parseFloat(@model.get("lat")) + xOff, parseFloat(@model.get("lng")) + yOff)
            @icon = new google.maps.Marker
                position: pt
                animation: google.maps.Animation.DROP
                title: @model.get "title"
                icon: redIcon
                map: @map
                ZIndex: 1
                # labelContent: @model.get("date").format("MM Do 'YY")
                # labelClass: 'map-label hidden'
                # labelAnchor: new google.maps.Point(32, 0)
            @


    class Map extends Backbone.View
        tagName: "div"
        className: "map-canvas"
        filterByDate: (min, max, opts={}) ->
            inrange = []
            outrange = []
            if @collection?
                @collection.each (model) ->
                    date = model.get("date") 
                    if date >= min and date <= max
                        model.trigger "show", opts
                    else 
                        model.trigger "hide", opts
                # _.each markers.outrange, (outlier) ->
                #     outlier.setMap null
                # _.each markers.inrange, (inlier) ->
                #     unless inlier.icon.getMap()?
                #     inlier.setMap self.mapObj.map 
                #     {inrange: inrange, outrange: outrange}

        initialize: (attrs) ->
            @id = attrs.id;
            @markers = []
            @mapOptions =
                center: new google.maps.LatLng(35, -62)
                zoom: 2
                minZoom: 2
                # styles: themes['purple']
                mapTypeControl: false
                mapTypeId: google.maps.MapTypeId.ROADMAP
                zoomControlOptions: 
                  position: google.maps.ControlPosition.LEFT_CENTER
                panControlOptions:
                  position: google.maps.ControlPosition.LEFT_CENTER
              # get map object - needs fix
        render: ->
            @$el.attr("id", @id).appendTo(hub.getRegion("mapWrapper").$el)
            @map = new google.maps.Map(@el, @mapOptions);
            @
        setCollection: (collection) ->
            if @collection
                @stopListening(@collection)
            @collection = collection
            @bindCollectionListeners()
        bindCollectionListeners: ->
            @listenTo @collection, {
                "find": (story) =>
                    @plot story
            }
        plot: (story) ->
            j = story.toJSON()
            # Difference between stuff returned null from DB, or things never set. typeof null = "object"; LOL
            unless !j.lat? or !j.lng? or _.isUndefined(j.lat) or _.isUndefined(j.lng)
                story.marker = new MapMarker({model: story, map: @map}).render()
                markerIcon = story.marker.icon
                @bindEventsOnMarker story.marker
                markerIcon.setMap @map
                @markers.push markerIcon
                story.set("hasLocation", true)
            else 
                story.set("hasLocation", false)
            story.trigger "doneloading"
            @

        clear: ->
            _.each @markers, (marker) ->
                marker.setMap null
            @
        plotAll: ->
            if @collection?
                @collection.each (story) =>
                    @plot story

        bindEventsOnMarker: (markerObj) ->
            display = markerObj.$el.html()
            # On click, show data
            google.maps.event.addListener markerObj.icon, "click", =>
                console.log markerObj.model.toJSON()
                markerObj.model.trigger("showpopup")
                # cc story
                # self.infowindow.setContent display
                # self.infowindow.open self.map, @
            google.maps.event.addListener markerObj.icon, "mouseover", =>
                markerObj.model.trigger("highlight", false)
            google.maps.event.addListener markerObj.icon, "mouseout", =>
                markerObj.model.trigger("unhighlight", false)
            @

        # window.GoogleMap::addClusterListeners = ->
        #   self = @
        #   google.maps.event.addListener @map, 'zoom_changed', ->
        #     zoom =  self.map.getZoom()
        #     markers = self.markers
        #     console.log zoom
        #     if zoom > 6
        #       _.each markers, (marker) ->
        #         $(marker.label.labelDiv_).text("dfsfdsd")
        #     else 
        #       _.each markers, (marker) ->
        #         $(marker.label.labelDiv_).addClass("hidden")



    MapFactory = do ->
        currentId = 0;

        return ->
            new Map("canvas-" + ++currentId);

    map = null;

    dispatcher.on "add:map", ->
        if map is null
            map = MapFactory().render()


    dispatcher.on "clear:map", ->
        map.clear()

    dispatcher.on "plot:story", -> map.plot.apply(map, arguments);

    dispatcher.on "plotAll:stories", -> map.plotAll.apply(map, arguments);

    dispatcher.on "set:activeStories", (stories) ->
        map.setCollection(stories);
        map.plotAll();

    dispatcher.on "filter:markers", (min, max, opts={}) ->
        _.extend {hideTimelineMarkers: true, hideMapMarker: true}, opts
        map.filterByDate min, max, opts

    return {
        getActiveMap: -> map
        Factory: MapFactory
    }