$ ->
    window.models = {}
    window.collections = {}

    ### Data Models ###
    window.models.Article = Backbone.Model.extend
        idAttribute: 'title'
    window.collections.Articles = Backbone.Collection.extend
        model: models.Article
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
            _.each @models, (article) ->
                date = article.get("date")
                if date instanceof Date == false
                    article.set "date", new Date(date)
                marker = article.marker
                if marker?
                    if date < hidate and date > lodate
                        inrange.push marker
                    else
                        outrange.push marker
            {inrange: inrange, outrange: outrange}

    # Model for a single instance of a map, including all of the settings for the GMap,
    # the markers, and a collection of articles
    window.models.StoryMap = Backbone.Model.extend
        defaults: ->
            articles = new collections.Articles
            articles.parent_map = @
            {
                markers: []
                articles: articles
            }
        external_url: '/externalNews'
        initialize: ->
            _.bindAll @, "attachCoordinates", "getCalaisData", "getGoogleNews", "getYahooNews", "addArticle", "plot"
        checkExistingQuery: (query, callback) ->
            callback query
        # desc: takes an object (not a model) and formats its attributes by mapping the keys in the map to the 
        # rets: the formatted article, with all key mappings
        format: (article, map) ->
            _.each map, (val, key) ->
                unless typeof val == "function"
                    article[key] = article[val]
                else
                    article[key] = val.call @
            article
        # desc: checks if a story has been looked at by seeing if its title exists in the hashtable
        # If new, add it to collection
        # ret: this
        addArticle: (story, opts) ->
            articles = @get("articles")
            # ignore case for title
            title = story.title.toLowerCase().stripHTML()
            # check if the story exists
            unless articles._byTitle.hasOwnProperty(title)
                # if it doesn't add it and set it in the titles hashtable
                options = _.extend {}, opts
                articles.add article = new models.Article(@format(story, options.map)), options
                articles._byTitle[title] = article
            else 
                cc "story exists"
            @
        # desc: Issues a request to a curl script, retrieving google news stories
        # args: the query, the start index to search (0-56), and the done callback
        # rets: this
        # A note on infinitely chained callback sequences - 
        # say we want to call google news, then yahoo, then reuters, then al jazeera:
        # getGoogleNews "hello", 0, -> getYahooNews "hello", 0, -> getReutersNews 0, "nooo", -> getAlJazeeraNews "hello", 0, null
        getGoogleNews: (query, start, done) ->
            console.log(encodeURIComponent query.toLowerCase())
            if !query? then return false
            self = @
            $.get @external_url,
                source: 'google'
                q: query.toLowerCase()
                start: start || "0"
            , (data) ->
                # parse the json
                json = JSON.parse(data)
                console.log(json)
                # Once google news is exhausted, execute yhoo
                if json.responseDetails is "out of range start"
                    if done? 
                        done query, 0, null
                    return false
                # Get location data from OpenCalais for each story item
                _.each json.responseData.results, (story) ->
                    self.addArticle story, map: date: 'publishedDate'
                        
                self.getGoogleNews query, start + 32, done
            @
        getYahooNews: (query, start, done) ->
            # cc "Getting Yahoo " + query + " " + start
            if !query? then return false
            self = @
            $.get @external_url,
                source: 'yahoo'
                q: query.toLowerCase()
                start: start || "0"
            , (data) ->
                cc "returning from yahoo with "
                cc data
                response = JSON.parse(data)
                # cc response.bossresponse
                if response? and response.bossresponse? and response.bossresponse.news?
                    stories = response.bossresponse.news.results
                # unless there are no stories, plot the stories
                unless !stories?
                    _.each stories, (story) ->
                        console.log story.date
                        self.addArticle story, map: content: 'abstract', date: -> new Date(parseInt(story.date) * 1000)
                    # 1000 is the length of results returned by Yahoo
                    # if start <= 1000
                    if start <= 1000
                        self.getYahooNews query, start + 50, done
                    else if done? then done query, 0, null
                else if done? then done query, 0 , null
            @
        getCalaisData: (story, story_string, callback) ->
            self = @
            # Pass the title and the story body into calais
            $.get "/calais",
                content: story_string
            , (calaisjson) ->
                # parse the response object
                cc "calais return " + story_string
                cc calaisjson
                unless !calaisjson?
                    # Check each property of the returned calais object
                    _.each calaisjson.entities, (entity) ->
                      # If it contains a "resolutions" key, it has latitude and longitude
                      if entity.hasOwnProperty("resolutions")
                        breakval = true
                        _.each entity.resolutions, (coords) ->
                            if coords.latitude? and coords.longitude? 
                                cc "coords found"
                                callback story, {latitude: coords.latitude, longitude: coords.longitude}
                                return breakval = false
                            true
                        breakval
                return
            @
        # args: plain article object or model (will find correct model if plain obj) and lat long object
        # rets: the story with coords added in
        attachCoordinates: (article, coords) ->
            if article instanceof models.Article == false
                article = @get("articles")._byId[article.title]
            console.log coords
            console.log article
            _.extend article.attributes, coords
            article
        plot: (article) ->
            @get("map").plot article
            @

    # The global collection of all maps for a user, 
    # retrieved at runtime by the "Fetch" method, below
    window.collections.Maps = Backbone.Collection.extend
        url: 'maps.json'
        model: models.StoryMap