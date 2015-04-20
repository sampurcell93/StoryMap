### OLD CODE, needs to be refactored a LOT ###
define "timeline", ["hub", "user", "map", "BST"], (hub, user, map, BST) ->

  _format = user.getActiveUser()?.get("preferences").get "date_format"

  class DateRange extends Backbone.Model
    defaults: ->
      now = moment().valueOf()
      epoch = moment(0).valueOf()
      return {
        absoluteMinimum: epoch
        absoluteMaximum: now
        activeUpperValue: now
        activeLowerValue: epoch
        currentMinimum: epoch
        currentMaximum: now
      }
    init: ->
      @dates = []
    getStartDate: -> @dates[0];
    getEndDate: -> @dates[1];
    setEndDate: (end) ->
      end = new Date(end)
      @dates[1] = end.getTime();
    setStartDate: (start) ->
      start = new Date(start)
      @dates[0] = start.getTime();
    setAbsoluteUpperBound: (bound) ->
      # @$startElement.datepicker("option", "maxDate", new Date(bound))
      # @$endElement.datepicker("option", "maxDate", new Date(bound))
      @set("absoluteMaximum", bound);
    setAbsoluteLowerBound: (bound) ->
      # @$startElement.datepicker("option", "minDate", new Date(bound))
      # @$endElement.datepicker("option", "minDate", new Date(bound))
      @set("absoluteMinimum", bound);
    setCollection: (collection) ->
      if !collection? then throw Error("Invalid or null collection passed to Date Range.")
      if _.isEqual(collection, @collection) then return @
      @collection = collection
      min = max = collection.first().get("date").valueOf()
      collection.each (model) =>
        date = model.get("date").valueOf()
        if date > max then max = date
        if date < min then min = date
      @set({
        "absoluteMinimum": min
        "absoluteMaximum": max
        "activeLowerValue": min
        "activeUpperValue": max
        "currentMinimum": min
        "currentMaximum": max
      });



  dispatcher = hub.dispatcher;

  class TimelineView extends Backbone.View
    el: "footer"
    initialize: (attrs) ->
      @format = _format
      @isPlaying = false
      _.extend @, attrs
      _.bindAll @, "updateVisibleMarkers"
      if @collection? then @setCollection @collection
      @bindJqueryUIRangeSlider();
      @listenToDateRange()
      @
    listenToDateRange: ->
      @listenTo @dateRange, {
        "change:absoluteMinimum change:currentMinimum change:activeLowerValue change:activeUpperValue change:absoluteMaximum change:currentMaximum": (range, date, obj) =>
          @updateRenderedBounds()
          # @$timeline.slider("option", min: date.valueOf())
        # "change:absoluteMaximum": (range, date, obj) =>
        #   @updateRenderedBounds()
          # @$timeline.slider("option", max: date.valueOf())
      }
    bindJqueryUIRangeSlider: ->
      @$timeline = @$(".slider")
      dataApplicator = (e, ui) =>
        $handle = $(ui.handle)
        pos   = $handle.index() - 1
        range = ui.values
        cleanedDate = moment(range[pos]).format(@format)
        @updateDateHandle($handle, cleanedDate)
        @updateVisibleMarkers(ui.values[0], ui.values[1]);
      @$timeline.slider
        range: true
        values: [@dateRange.get("absoluteMinimum"), @dateRange.get("absoluteMaximum")]
        step: 10000
        slide: (e, ui) => dataApplicator.apply(@, arguments);
        change: (e, ui) => dataApplicator.apply(@, arguments);
    updateDateHandle: (handle, date) ->
      display = $("<div/>").addClass("handle-display-value").text date
      handle.find("div").remove().end().append display
    updateVisibleMarkers:  (lowBound, highBound) ->
      inBounds = @BST.betweenBounds({$gte: lowBound, $lte: highBound });
      outBounds = @BST.betweenBounds({$lt: lowBound}).concat(@BST.betweenBounds({$gt: highBound}));
      _.each inBounds, (inbound) =>
        inbound.trigger("show");
      _.each outBounds, (outbound) =>
        outbound.trigger("hide");
      @prevHighBound = highBound
      # console.log(inBounds, outBounds);
    # Expects a DateRange object
    setRange: (range) ->
      if !range? then throw Error("Invalid range supplied to Timeline View.")
      @dateRange = range
      @
    getRange: -> @dateRange
    # Expects a Backbone.Collection, constructs the list into a BST
    setCollection: (collection) ->
      if !collection? then throw Error("Invalid or null collection passed to Timeline View.")
      if _.isEqual(collection, @collection) then return @
      @collection = collection
      @_constructBST();
      @updateRenderedBounds();
      # console.log @BST.betweenBounds({$gte: Date.now() - 10000000, $lte: Date.now()})
      @
    updateRenderedBounds: () ->
      # cache the timeline obj
      $timeline = @$timeline
      currMin = @dateRange.get("currentMinimum")
      currMax = @dateRange.get("currentMaximum")
      activeMin = @dateRange.get("activeLowerValue")
      activeMax = @dateRange.get("activeUpperValue")

      if currMin < activeMin
        @dateRange.set("activeLowerValue", currMin)
        activeMin = @dateRange.get("activeLowerValue")

      if currMax < activeMax
        @dateRange.set("activeUpperValue", currMax)
        activeMax = @dateRange.get("activeUpperValue")

      console.log "currMin", new Date(currMin), "currMax", new Date(currMax)
      console.log "activemin", new Date(activeMin), "activeMax", new Date(activeMax)
      # get handles and set their display data to clean dates
      handles = $timeline.find(".ui-slider-handle")
      # handles.first().data("display-date", moment(min).format(@format))
      # handles.last().data("display-date", moment(max).format(@format))
      # Set the slider values to each end of the spectrum and update the min and max

      $timeline.slider("option", min: currMin, max: currMax)
      $timeline.slider("values", 0, activeMin)
      $timeline.slider("values", 1, activeMax)
      @
    _constructBST: ->
      @BST = new BST.BST compareKeys: (a, b) ->
        if a < b then return -1
        if a > b then return 1
        return 0
      @collection.each (model) =>
        @BST.insert(model.get(@index)?.toDate(), model);
      @
    hide: ->
      @$el.css "bottom", -400
      @
    show: ->
      @$el.fadeIn("fast").css "bottom", 0
    addMarker: (model) ->
      $slider = @$(".slider-wrapper")
      pos = new Date(model.get(@index)).getTime()
      pos = (pos -@min)/(@max - @min)
      view = new TimelineMarker model: model, left: pos
      $slider.append view.render().el
      @
    getPlayer: ->
      lowBound = @dateRange.get("currentMinimum");
      highBound = @dateRange.get("currentMaximum");
      increment = Math.ceil(Math.abs (highBound - lowBound) / 300)
      play = =>
        newVal = @dateRange.get("activeUpperValue") + increment
        @dateRange.set("activeUpperValue", newVal)
        if newVal >= @dateRange.get("currentMaximum")
          @$(".js-pause-timeline").trigger("click");
          return;
        @player = requestAnimationFrame(play);
      return =>
        @dateRange.set("activeUpperValue", lowBound);
        @player = requestAnimationFrame(play);
    toEnd: ->
      $tl = @$timeline
      @stop()
      $tl.slider("values", 1, @dateRange.get("absoluteMaximum"))
    toStart: ->
      $tl = @$timeline
      @stop()
      start = $tl.slider("values", 1, @dateRange.get("absoluteMinimum"))
    stop: -> 
      cancelAnimationFrame(@player);
      @
    events: 
      "click .js-play-timeline": (e) ->
        $(e.currentTarget).removeClass("js-play-timeline icon-play2").addClass "js-pause-timeline icon-pause2 playing"
        play = @getPlayer()
        play()
      "click .js-pause-timeline": (e) ->
        $(e.currentTarget).removeClass("js-pause-timeline icon-pause2 playing").addClass "js-play-timeline icon-play2"
        @stop();
      "switch .js-pause-timeline": (e) ->
        $(e.currentTarget).removeClass("js-pause-timeline icon-pause2 playing").addClass "js-play-timeline icon-play2"
      "click .js-fast-forward": "renderSpeed"
      "click .js-rewind": "renderSpeed"
      "click .js-to-end": "toEnd"
      "click .js-to-start": "toStart"
      "mouseover .timeline-controls li": (e) ->
        $t = $ e.currentTarget  


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
          if !@model.hasCoordinates() then $el.addClass("no-location-marker")
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


  class TwoDatePicker
      constructor: (opts={}) ->
        _.extend @, opts
        @$startElement = $(@startElement)
        @$endElement = $(@endElement)
        @bindDatePicker(@$startElement, "start");
        @bindDatePicker(@$endElement, "end");
        _.extend @, Backbone.Events
        @bindRangeListeners()
        @updateCurrentMinimum(null, @dateRange.get("currentMinimum"))
        @updateCurrentMaximum(null, @dateRange.get("currentMaximum"))
      bindRangeListeners: ->
        @listenTo @dateRange, {
          "change:currentMaximum": @updateCurrentMaximum
          "change:currentMinimum": @updateCurrentMinimum
        }
      updateCurrentMaximum: (model, max) ->
        @$endElement.datepicker("setDate", new Date(max));
      updateCurrentMinimum: (model, min)->
        @$startElement.datepicker("setDate", new Date(min));
      # Takes in an element to bind datepicker to, and whether it is start or end
      bindDatePicker: (el, which) ->
        el.datepicker({
          maxDate: @dateRange.get("absoluteMaximum")
          minDate: @dateRange.get("absoluteMinimum")
          showAnim: "fadeIn"
          inline: true,
          showOtherMonths: true,
          dayNamesMin: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          onSelect: (date, evt) =>
            date = moment(date).valueOf();
            console.log moment(date).format("M/D/YY")
            currentMinimum = @dateRange.get("currentMinimum")
            currentMaximum = @dateRange.get("currentMaximum")
            el.blur()
            if which is "start"
              @dateRange.set("currentMinimum", date);
            else 
              @dateRange.set("currentMaximum", date);
          onClose: ->
            el.blur()
        })
      destroy: ->
        @stopListening();
      setTimelineInterface: (@timelineInterface) ->

  TimelineFactory = ->
    return (opts = {})->
      opts = _.extend {
        index: "date"
        dateRange: new DateRange(),
        collection: new Backbone.Collection
      }, opts
      return new TimelineView(opts);
      
  TwoDatePickerFactory = ->
    return (opts={})->
      opts = _.extend({
        dateRange: new DateRange(),
        startElement: document.getElementById("start-date-picker")
        endElement: document.getElementById("end-date-picker")
      }, opts)
      range = range || new DateRange()
      picker = new TwoDatePicker(opts)


  return {
      TimelineFactory: TimelineFactory
      TwoDatePickerFactory: TwoDatePickerFactory
  }