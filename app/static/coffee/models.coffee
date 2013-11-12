$ ->

    # desc: takes an object (not a model) and formats its attributes by modifying its key structure (never destructive)
    # rets: the formatted article, with all key mappings
    format = (story, map) ->
        _.each map, (val, key) ->
            unless typeof val == "function"
                story[key] = story[val]
            else
                story[key] = val.call story
        story

    ### Data Models ###

    window.models.Query = Backbone.Model.extend
        url: -> "/queries/" + (@get("id") || @get("title"))
        external_url: '/externalNews'
        initialize: (attrs, options) ->
            _.bindAll @, "getYahooNews", "getGoogleNews", "exists"
            @map = new window.GoogleMap @
            try @get("stories").parent_map = options.map
        defaults: ->
            stories: new collections.Stories
        parse: (model) ->
            if model.query?
                obj = model.query
            else 
                obj = model
            @value = obj.title
            @tokens = [ obj.title ]
            stories = new collections.Stories()
            _.each obj.stories, (story) ->
                stories.add new models.Story(story)
            obj.stories = stories
            if obj.created? then obj.created = new Date(obj.created)
            if obj.last_query? then obj.last_query = new Date(obj.last_query)
            obj
        exists: (exists_callback, fails_callback) ->
            querytitle = @get("title")
            self = @
            $.get("/queries/" + querytitle, {}, (response)->
                try response = JSON.parse(response)
                cc response
                # the query exists then execute the success callback
                if response.exists != false and exists_callback?
                    self.id = response.id
                    self.set("id", response.id)
                    console.log self
                    exists_callback querytitle
                else if fails_callback?
                    fails_callback self, new models.Query(response, {parse: true})
            )
            @
        favorite: ->
            user.get("queries").add @
            user_id = window.user.id
            query_id = @id || @get("id")
            $.post "/favorite", {
                user_id: user_id
                query_id: query_id
            }, (resp) ->
                resp = JSON.parse resp
                cc resp
                cc "THIS MAP HAS BEEN FAVORITED"
         # desc: checks if a story has been looked at by seeing if its title exists in the hashtable
        # If new, add it to collection
        # ret: this
        addStory: (story, opts) ->
            stories = @get("stories")
            # ignore case for title
            title = story.title.toLowerCase().stripHTML()
            # check if the story exists
            unless stories._byTitle.hasOwnProperty(title)
                cc "adding story"
                # if it doesn't add it and set it in the titles hashtable
                options = _.extend {}, opts
                stories.add story = new models.Story(format(story, options.map)), options
                id = @get("id") || @id
                if id then story.set("query_id", id)
                stories._byTitle[title] = story
            else 
                cc "story exists"
            @
        # desc: Issues a request to a curl script, retrieving google news stories
        # args: the query, the start index to search (0-56), and the done callback
        # rets: this
        # A note on infinitely chained callback sequences - 
        # say we want to call google news, then yahoo, then reuters, then al jazeera:
        # getGoogleNews "hello", 0, -> getYahooNews "hello", 0, -> getReutersNews 0, "nooo", -> getAlJazeeraNews "hello", 0, null
        getGoogleNews: (start, done) ->
            self = @
            query = @get("title")
            start || (start = 0)
            $.get @external_url,
                source: 'google'
                q: query.toLowerCase()
                start: start 
            , (response) ->
                console.count "google news story set returned"
                # parse the json
                try 
                    response = JSON.parse(response)
                    console.log response
                    # Once google news is exhausted, execute yhoo
                    if response.responseDetails is "out of range start" or response.responseDetails is "Invalid start" or start > 64
                        if done? 
                            console.log done
                            done 0, null
                    # Get location data from OpenCalais for each story item
                    _.each response.responseData.results, (story) ->
                        self.addStory story, map: 
                            date: ->
                                new Date(this['publishedDate'])
                            type: -> 'google'
                            url: 'unescapedUrl'
                    if start < 64 then return self.getGoogleNews start + 32, done
            @
        getYahooNews: (start, done) ->
            query = '"' + @get("title").toLowerCase() + '"'
            start || (start = 0)
            self = @
            $.get @external_url,
                source: 'yahoo'
                q: query
                start: start
            , (response) ->
                response = JSON.parse response
                try 
                    console.count "yahoo news story set returned"
                    # get all news, including metadata
                    news = response.bossresponse.news
                    # get the stories
                    stories = news.results
                    # get total results
                    total = 200 #news.totalresults
                    _.each stories, (story) ->
                        self.addStory story, map:
                            content: 'abstract'
                            date: -> new Date(parseInt(story.date) * 1000)
                            type: -> 'yahoo'
                            'publisher': 'source'
                    # 1000 is the length of results returned by Yahoo
                    # if start <= 1000
                    if start <= total
                        self.getYahooNews start + 50, done
                    else if done? 
                        console.log done
                        done 0, null
                catch 
                    if done? 
                        console.log done
                        done 0 , null
            return @

    window.collections.Queries = Backbone.Collection.extend
        model: models.Query
        url: "/queries"
        parse: (response) -> 
            cc response.queries[0]
            cc "parsing collection"
            response.queries


    window.models.Story = Backbone.Model.extend
        url: ->
            url = "/stories"
            if @id then url += "/" + @id
            url
        loading: false
        defaults: 
            hasLoaded: false
        initialize: ->
            @on
                "loading": ->
                    this.loading = true
                "doneloading": ->
                    this.loading = false
        # args: an array of objects to attach to the model, and whether to plot the model after
        # the applyfun pair of each object can hold a mapping function to apply to each of the other values
        # rets: the story with coords added in
        attach: (objects, plot) ->
            self = @
            @trigger("loading")
            _.each objects, (obj) ->
                applyfun = obj.applyfun
                if applyfun?
                    for i of obj
                        cc i
                        unless obj[i] == applyfun
                            obj[i] = applyfun.apply(self,[obj[i]])
                _.extend self.attributes, obj
            if plot == true
                @plot()
            @
        # Expects a callback
        getCalaisData: (callback) ->
            self = @
            try 
                j = @toJSON()
                story_string = j.title + j.content
            catch 
                return console.error("Badly formatted model passed to calais")
            # Pass the title and the story body into calais
            $.get "/calais",
                content: story_string
            , (calaisjson) ->
                unless !calaisjson?
                    console.count "calais data returned for " + j.title
                    self.parseCalais calaisjson, {plot: true}

            @
        parseCalais: (json, opts) ->
            options = _.extend {plot: true}, opts
            self = @
             # Check each entity property of the returned calais object searching for locations
            _.each json.entities, (entity) ->
              # If it contains a "resolutions" key, it has latitude and longitude
              if entity.hasOwnProperty("resolutions")
                breakval = true
                _.each entity.resolutions, (coords) ->
                    if coords.latitude? and coords.longitude?
                        self.attach [{
                            applyfun: parseFloat
                            lat: coords.latitude 
                            lng: coords.longitude
                        }], options.plot
                        # Mark this as a model with a location
                        self.set("hasLocation", true)
                        return breakval = false
                    true
                breakval
        plot: ->
            window.mapObj.plot @
            @
    ( ->

        sortMethods = {
            "newest": (story) ->
                story.get("date")
            "oldest": ->
                -story.get("date")
        }

        window.collections.Stories = Backbone.Collection.extend
            model: models.Story
            _byTitle: {}
            initialize: (opts) ->
                # If the collection is the child of a news map, save a reference to the map
                if opts? and opts.parent_map then @parent_map = opts.parent_map
                @_byTitle = {}
                @
            filterByDate: (lodate, hidate) ->
                self = @
                inrange = []
                outrange = []
                # console.log @get("articles").models
                _.each @models, (story) ->
                    date = story.get("date")
                    if date instanceof Date == false
                        story.set "date", new Date(date)
                    markerObj = story.marker
                    if markerObj?
                        marker = markerObj.marker
                        if date < hidate and date > lodate
                            inrange.push marker
                        else
                            outrange.push marker
                {inrange: inrange, outrange: outrange}
    )()