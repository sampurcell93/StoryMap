### OLD CODE, needs to be refactored a LOT ###
define ["hub", "user"], (hub, user) ->

    dispatcher = hub.dispatcher;

    class Timeline extends Backbone.View
        el: 'footer'
        speeds: { forward : 32, back : 32 }
        dir: "forward"
        initialize: ->
          format = user.getActiveUser()?.get("preferences").get "date_format"
          _.bindAll @, "render", "addMarker", "changeValue", "play", "stop", "updateHandles"
          # callback to run each time the timeline is changed
          update_val = (e, ui) =>
            handle = $ ui.handle
            pos = handle.index() - 1
            range  =  ui.values
            # Convert the slider's current value to a readable string
            cleaned = moment(range[pos]).format(format)
            # Display said string
            display = $("<div/>").addClass("handle-display-value").text cleaned 
            handle.find("div").remove().end().append display
            dispatcher.dispatch "filter:markers", ui.values[0], ui.values[1], {
              hideTimelineMarkers: false
            }
            # self.map.toggleMarkers self.collection.filterByDate(ui.values[0], ui.values[1])
          # Make a jquery ui slider element
          @$timeline = @$(".slider")
          @$timeline.slider
            range: true
            values: [0, 100]
            step: 10000
            slide: update_val
            change: update_val
          @
        reset: ->
          @min = @max = undefined
          @
        clearMarkers: ->
          @$(".timeline-marker").remove()
          @
        render: ->
          @clearMarkers()
          _.each @collection.models, (story) =>
            @addMarker story
          @
        addMarker: (model) ->
          console.log "appending a MARKR ONTO TIMELINE"
          # Get the slider and compute its pixel width so we can offset each marker (UI purposes)
          # I'd rather not touch the math on the slider mechanism itself
          $slider = @$(".slider-wrapper")
          width = $slider.width()
          # If it's already a date, this still works :D
          pos = model.get("date").unix()*1000
          range = @max - @min
          pos -= @min
          pos /= range
          # pixel offset -> percentage of width -> add to actual percent for SMOOV UI
          pixeladdition = 10/width
          # pos += pixeladdition
          # Calculate a percentage for the article and pass into marker view
          view = new TimelineMarker model: model, left: pos
          $slider.append view.render().el
          @
        play: ->
          values = @$timeline.slider "values"
          lo = values[0]
          hi = values[1]
          # @updateHandles()
          @isPlaying = true
          dir = if @dir == "forward" then 1 else 1
          # start the tree
          inc = dir*Math.ceil(Math.abs (hi - lo) / 300)
          @changeValue lo, hi, inc, (locmp, hicmp) ->
            locmp <= hicmp
          @
        stop: ->
          @isPlaying = false
          @$(".js-pause-timeline").trigger "switch"
          @
        toEnd: ->
          $tl = @$timeline
          @stop()
          end = $tl.slider("option", "max")
          $tl.slider("values", 1, end)
          end
        toStart: ->
          $tl = @$timeline
          @stop()
          start = $tl.slider("values", 0)
          $tl.slider("values", 1, start)
          start
        # Recursive function animates slider to auto play!
        changeValue: (lo, hi, increment, comparator) ->
          window.setTimeout =>
            if comparator(lo, hi) is true and @isPlaying is true
              newlo = lo + increment
              @$timeline.slider("values", 1, newlo)
              @changeValue newlo, hi, increment, comparator
            else
              @stop()
          , @speeds[@dir]
          @
        # Usually, if we already have a mn and a max set, we don't need to do this. If the force param is true, do it anyway
        updateHandles: () ->
          if @collection.length < 2 then return @
          prevcomparator = @collection.comparator
          @collection.comparator = (model) ->
            return model.get("date")
          format = user.getActiveUser()?.get("preferences").get "date_format"
          @collection.sort()
          @min = min = @collection.first().get("date")
          @max = max = @collection.last().get("date")
          if !max.toDate?
            @max = max = moment max
          if !min.toDate?
            @min = min = moment min
          mindate = parseInt(min.unix()*1000)
          maxdate = parseInt(max.unix()*1000)
          # cache the timeline obj
          $timeline = @$timeline
          # get handles and set their display data to clean dates
          handles = $timeline.find(".ui-slider-handle")
          handles.first().data("display-date", min.format(format))
          handles.last().data("display-date", max.format(format))
          # Set the slider values to each end of the spectrum and update the min and max
          $timeline.slider("option", min: mindate, max: maxdate)
          $timeline.slider("values", 0, mindate)
          $timeline.slider("values", 1, maxdate)
          @max = @max.unix()*1000
          @min = @min.unix()*1000
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

        # Expects either a date string or date object
        zoomTo: (date) ->
          if !@min or !@max then return @
          center = moment(date).unix()*1000
          offsetL = (@max - center)/2
          offsetH = (center - @min)/2
          offset = if offsetL > offsetH then offsetH else offsetL
          $t   = @$timeline
          low = (parseInt(center - offset))
          high = (parseInt(center + offset))
          $t.slider("values", 0, low)
          $t.slider("values", 1, high)
          @

        events: 
          "click .js-play-timeline": (e) ->
            $(e.currentTarget).removeClass("js-play-timeline icon-play2").addClass "js-pause-timeline icon-pause2 playing"
            @play() unless @isPlaying
          "click .js-pause-timeline": (e) ->
            $(e.currentTarget).removeClass("js-pause-timeline icon-pause2 playing").addClass "js-play-timeline icon-play2"
            @stop()
          "switch .js-pause-timeline": (e) ->
            $(e.currentTarget).removeClass("js-pause-timeline icon-pause2 playing").addClass "js-play-timeline icon-play2"
          "click .js-fast-forward": "renderSpeed"
          "click .js-rewind": "renderSpeed"
          "click .js-to-end": "toEnd"
          "click .js-to-start": "toStart"
          "mouseover .timeline-controls li": (e) ->
            $t = $ e.currentTarget  
        destroy: ->
            @undelegateEvents();
            @$el.removeData().unbind(); 


    class TimelineMarker extends Backbone.View
        className: 'timeline-marker'
        template: _.template($("#date-bubble").html())
        initialize: (attrs) ->
            @left = attrs.left
            @listenTo @model,
                "hide": (opts={}) ->
                  @$el.hide() unless opts.hideTimelineMarkers is false
                "show": (opts={}) ->
                  @$el.show()
                "highlight": ->
                  @$el.addClass("highlighted")
                "unhighlight": ->
                  @$el.removeClass("highlighted")
                "change:hasLocation": (model, hasLocation)->
                    if hasLocation then @$el.removeClass("no-location-marker")
                    else @$el.addClass("no-location-marker")
        render: ->
            format = user.getActiveUser()?.get("preferences").get "date_format"
            num = @left
            $el = @$el
            $el.css('left', (num*100) + "%")
            $el.html(@template(date: @model.get("date").format(format)))
            if !@model.hasLocation() then $el.addClass("no-location-marker")
            @$(".date-bubble").hide()
            @
        events:
          "mouseover": ->
            @model.trigger("highlight")
          "mouseout": ->
            @model.trigger("unhighlight")
          "click": (e) ->
            @model.trigger "showpopup"
            # $(".date-bubble").hide()
            # @$(".date-bubble").toggle('fast')

    return {
        TimelineView: Timeline
    }