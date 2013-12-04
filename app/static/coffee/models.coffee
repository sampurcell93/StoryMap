$ ->
    ### Data Models ###

    window.models.Query = Backbone.Model.extend
        url: -> "/queries/" + (@get("id") || @get("title"))
        external_url: '/externalNews'
        initialize: (attrs, options) ->
            _.bindAll @, "getYahooNews", "getGoogleNews", "exists", "addStory"
            @map = window.mapObj
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
                stories.add new models.Story(story, {parse: true})
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
        addStory: (story) ->
            stories = @get("stories")
            story.date = new Date(story.date)
            # ignore case for title
            title = story.title.toLowerCase().stripHTML()
            # check if the story exists
            unless stories._byTitle.hasOwnProperty(title)
                # if it doesn't add it and set it in the titles hashtable
                stories.add story = new models.Story story
                id = @get("id") || @id
                if id then story.set("query_id", id)
                stories._byTitle[title] = story
                story.plot()
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
            cc "calling gnews"
            self = @
            query = @get("title")
            start || (start = 0)
            $.get @external_url,
                source: 'google'
                q: query.toLowerCase()
                start: start 
            , (stories) ->
                console.count "google news story set returned"
                stories = JSON.parse(stories)
                cc stories
                # Once google news is exhausted, execute callback 
                if (start > 64 or !stories.length) and done? then done 0, null
                # Get location data from OpenCalais for each story item
                _.each stories, self.addStory
                # Otherwise, call self and keep going
                if start < 64 then self.getGoogleNews start + 8, done
            @
        getYahooNews: (start, done) ->
            query = '"' + @get("title").toLowerCase() + '"'
            start || (start = 0)
            self = @
            $.get @external_url,
                source: 'yahoo'
                q: query
                start: start
            , (stories) ->
                stories = JSON.parse stories
                console.count "yahoo news story set returned"
                # get all news, including metadata
                total = 10 #news.totalresults
                _.each stories, self.addStory
                # if start <= 1000
                if start <= total then self.getYahooNews start + 50, done
                else if done? then done 0, null
                return @
        getFeedZilla: (done) ->
            self = @
            $.get "http://api.feedzilla.com/v1/articles.json", {
                q: @get("title")
                count: 100
            }, (response) ->
                _.each response.articles, (story) ->
                    cc "adding feedzilla sroy"
                    self.addStory story, map: 
                        content: 'summary'
                        publisher: 'source'
                        date: -> new Date(story.publish_date)
                        aggregator: -> 'FeedZilla'

    window.collections.Queries = Backbone.Collection.extend
        model: models.Query
        url: "/queries"
        parse: (response) -> 
            # cc response.queries[0]
            # cc "parsing collection"
            response.queries


    window.models.Story = Backbone.Model.extend
        url: ->
            url = "/stories"
            if @id then url += "/" + @id
            url
        geocodeUrl: 'http://maps.googleapis.com/maps/api/geocode/json?sensor=true&address='
        loading: false
        defaults: 
            hasLoaded: false
        initialize: ->
            _.bindAll @, "geocode"
            @on
                "loading": ->
                    this.loading = true
                "doneloading": ->
                    this.loading = false
                "change:hasLocation": (model, value) ->
                    if value == true
                        this.collection._withLocation[this.get("title")] = this
                        console.log this.collection
        hasLocation: ->
            @get("lat")? and @get("lng")
        plot: ->
            window.mapObj.plot @
            @
        # If a user has an address they can manually enter it and geocode
        geocode: (address, callback) ->
            self = @
            console.log self
            $.getJSON @geocodeUrl + encodeURIComponent(address), 
                (response) ->
                    try 
                        coords = response.results[0].geometry.location
                        self.save {lat: coords.lat, lng: coords.lng, location: response.results[0].formatted_address} , 
                            success: (model, resp) ->
                                self.set("hasLocation", true)
                                self.plot()
                            error: (model, resp) ->
                        if callback? then callback(true,coords)
                    catch
                        console.log _error
                        if callback? then callback(false,null)


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
            _withLocation: {}
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