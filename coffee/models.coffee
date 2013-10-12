$ ->

    window.models = {}
    window.collections = {}

    ### Data Models ###
    window.models.Article = Backbone.Model.extend()
    window.collections.Articles = Backbone.Collection.extend
        model: models.Article
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
                date = article.get("date").getTime()
                marker = article.get("marker")
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
        initialize: ->
            _.bindAll @, "formCalaisAndPlot", "getCalaisData", "getGoogleNews", "getYahooNews"
        # desc: Issues a request to a curl script, retrieving google news stories
        # args: the query, the start index of to search (0-56), and the done callback
        # rets: this
        # A note on infinitely chained callback sequences - 
        # say we want to call google news, then yahoo, then reuters, then al jazeera:
        # getGoogleNews "hello", 0, -> getYahooNews "hello", 0, -> getReutersNews 0, "nooo", -> getAlJazeeraNews "hello", 0, null
        getGoogleNews: (query, start, done) ->
            if !query? then return false
            self = @
            $.get "./get_google_news.php",
                q: query.toLowerCase()
                start: start
            , (data) ->
                # parse the json
                json = JSON.parse(data)
                # Once google news is exhausted, execute yhoo
                if json.responseDetails is "out of range start"
                    if done? 
                        done query, 0, null
                    return false
                # Get location data from OpenCalais for each story item
                _.each json.responseData.results, (story) ->
                    self.getCalaisData  story, story.titleNoFormatting + story.content, self.formCalaisAndPlot
                self.getGoogleNews query, start + 32, done
            @
        getYahooNews: (query, start, done) ->
            # cc "Getting Yahoo " + query + " " + start
            if !query? then return false
            self = @
            $.get "./get_yahoo_news.php",
                q: query.toLowerCase()
                start: start
            , (data) ->
                response = JSON.parse(data)
                # cc response.bossresponse
                if response? and response.bossresponse? and response.bossresponse.news?
                    stories = response.bossresponse.news.results
                # unless there are no stories, plot the stories
                unless !stories?
                    _.each stories, (story) ->
                        self.getCalaisData story, story.title + story.abstract, self.formCalaisAndPlot
                    cc start
                    # 1000 is the length of results returned by Yahoo, so once we hit that, execute any callback for new data
                    if start < 0
                        self.getYahooNews query, start + 50, done
                    else if done? then done query, 0, null
                    return
                # if there were no stories and there is a callback, execute it.
                if done? then done query, 0 , null
            @
        getCalaisData: (story, story_string, callback) ->
            self = @
            console.log "getting data"
            # Pass the title and the story body into calais
            $.get "./calais.php",
                content: story_string
            , (data) ->
                cc "returning from calais"
                # parse the response object
                calaisjson = JSON.parse(data)
                unless calaisjson? then return
                # Check each property of the returned calais object
                for i of calaisjson
                  # If it contains a "resolutions" key, it has latitude and longitude
                  if calaisjson[i].hasOwnProperty("resolutions")
                    callback(story, calaisjson, i)
                    break
                return
            @
        formCalaisAndPlot: (fullstory, calaisjson, i) ->
            calaisObj = _.extend {}, fullstory
            calaisObj.latitude = calaisjson[i].resolutions[0].latitude
            calaisObj.longitude = calaisjson[i].resolutions[0].longitude
            # Set the date in order to make the range slider
            calaisObj.date = new Date calaisjson.doc.info.docDate
            # It's a valid story - push it
            @get("articles").add article = new models.Article(calaisObj)
            # Plot the story en el mapa
            @get("map").plotStory article
            @

    # The global collection of all maps for a user, 
    # retrieved at runtime by the "Fetch" method, below
    window.collections.Maps = Backbone.Collection.extend
        url: 'maps.php'
        model: models.StoryMap

    # Instantiate new collection of all maps
    window.AllMaps = new collections.Maps()
    # Get all existing maps from server
    window.AllMaps.fetch 
        success: (collection, response) ->
            if collection.length is 0
                collection.add new models.StoryMap()
            else 
                cc "Now we want to go to the route for all saved maps"

        error: (collection, response) ->