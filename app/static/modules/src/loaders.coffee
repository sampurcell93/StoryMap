define "loaders", ["hub", "stories"], (hub, stories) ->

    class SpinningLoader
        constructor: -> @
        get: -> '<div class="spinner"><div class="rect1"></div><div class="rect2"></div><div class="rect3"></div><div class="rect4"></div><div class="rect5"></div></div>'

    transitionFn = (diff, currentVal, step, count) ->
        @el.attr("value", currentVal + step)
        # @number.css("left", (currentVal + step / 100) + "%")
        currentVal += step;
        args = arguments
        if count > @totalSteps
            cancelAnimationFrame @animationFrame
        else
            requestAnimationFrame => 
                count++
                transitionFn.apply @, args

    class Progressbar
        reset: ->
            @el.attr("value", 0)
        getDefaultBar: ->
            $("<progress min='0' max='100' value='0' class='hidden'></progress>")
        constructor: (@el, @number=0) -> 
            _.extend @, Backbone.Events
            _.bindAll @, "set"
            @animationFrame = null
            if !@el?
                @el = @getDefaultBar()
            @
        createListener: ->
            @listener = new FeedAnalysisProgress(@el, @name)
        max: 100
        totalSteps: 20
        get: ->
            parseInt @el.attr("value")
        reset: -> 
            @stop()
            @el.attr("value", 0);
        show: -> 
            @el.slideDown "fast"
            @number.fadeIn "fast"
            @
        hide: -> 
            @number.fadeOut "fast"
            @el.slideUp "fast"
            @
        set: (val, count=0, diff) ->
            currentVal = parseInt(@el.attr "value");
            diff = val - currentVal
            step = diff / @totalSteps
            transition = requestAnimationFrame => 
                transitionFn.call(@, diff, currentVal, step, 0)
        setText: (text) ->
            @number.text(text);
        # Adapter
        updatePercentage: (newPercentage) ->
            @set(newPercentage)
            # i = setInterval =>
            #     @el.attr("value", currentVal + step)
            #     currentVal += step;
            #     count++
            #     if count >= totalSteps 
            #         clearInterval i
            # , 50
            @


    class FeedAnalysisProgress extends Progressbar
        constructor: (@el, @name) ->
        # Monitors two values on a query request object:
        # the current 
        monitorChanges: (requestObj, name) ->
            requestObj.on "addedStories:#{name}", ->
            requestObj.on "retrieval_#{name}:done", =>
                totalStoriesRetrieved = requestObj.totalStoriesRetrieved[name];
                activeStories = stories.getActiveSet() ;
                group = activeStories.getGroup(name);
                group.on "done:analysis", =>
                    totalStoriesRetrieved.analyzed += 1;
                    console.log totalStoriesRetrieved
                    @updatePercentage(totalStoriesRetrieved.analyzed/totalStoriesRetrieved.retrieved);
                    if totalStoriesRetrieved.analyzed >= totalStoriesRetrieved.retrieved
                        setTimeout => 
                            @el.li?.fadeOut("fast", -> @remove())
                        , 2400
                # stories.analyze(name);
        render: ->
            hub.getRegion("feedLoaderWrapper").$el.append li = $("<li/>").html(@el).attr("data-name", @name);
        updatePercentage: (newPercentage) ->
            @el.set(@el.max * 100)

    SVG = do ->
        svgNS = "http://www.w3.org/2000/svg";  
        loaderDimension = 100;
        _colors = {
            google: "white"
            yahoo: "yellow"
        }

        return (name) ->
            svg = document.createElementNS(svgNS, "svg");
            svg.setAttribute("xmlns:xlink", "http://www.w3.org/1999/xlink")
            svg.setAttribute("height", loaderDimension);
            svg.setAttribute("width", loaderDimension);
            svg.setAttribute("class", "feed-loader");
            rect = document.createElementNS(svgNS, "rect"); 
            rect.setAttribute("height", loaderDimension);
            rect.setAttribute("width", loaderDimension);
            rect.setAttribute("fill", _colors[name]);
            rect.setAttribute("y", loaderDimension);
            img = document.createElementNS(svgNS, "image");
            img.setAttributeNS('http://www.w3.org/1999/xlink','href',"./static/images/#{name}_loader.png");
            img.setAttribute("height", loaderDimension);
            img.setAttribute("width", loaderDimension);
            svg.appendChild(rect);
            svg.appendChild(img);
            {
                svg: svg
                listener: new FeedAnalysisProgress(svg, name)
                set: (newPercentage) ->
                    rect = svg.childNodes[0];
                    rect.setAttribute("y", loaderDimension - newPercentage * 100)
                max: -> parseInt(svg.getAttribute("height"));
            }


    class ProgressFactory
        getFeed: (type, name) ->
            # return SVG name
            p = new Progressbar()
            p.el.addClass(name)
            p.createListener();
            p
        getBar: ->
            return new Progressbar()
        getSpinner: ->
            return new SpinningLoader().get()
        get: (type, name) ->
            switch (type) 
                when "feedAnalysis" then return @getFeed.apply(@, arguments);
                when "generic" then return @getBar.apply(@, arguments)
                when "spinner" then return @getSpinner.apply @, arguments

    return ProgressFactory