$ ->
    # Quick logging
    window.cc = (arg) ->
        console.log arg

    window.models = {}
    window.collections = {}

    ### Data Models ###
    window.models.Article = Backbone.Model.extend()
    window.collections.Articles = Backbone.Collection.extend
        model: models.Article
        initialize: (opts) ->
            # If the collection is the child of a news map, save a reference to the map
            if opts? and opts.parent_map then @parent_map = opts.parent_map
            @

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
        # A function that issues a request to a curl script, retrieving google news stories
        getGoogleNews: (query, start, done) ->
            done = null
            if !query? then return false
            self = @
            # cc "./getnews.php?q=" + val + "&start=" + start
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
                self.getGoogleNews query, start + 8, done
            true
        formCalaisAndPlot: (fullstory, calaisjson, i) ->
            calaisObj = _.extend {}, fullstory
            calaisObj.latitude = calaisjson[i].resolutions[0].latitude
            calaisObj.longitude = calaisjson[i].resolutions[0].longitude
            # Set the date in order to make the range slider
            calaisObj.date = new Date calaisjson.doc.info.docDate
            # It's a valid story - push it
            @get("articles").add new models.Article(calaisObj)
            # Plot the story en el mapa
            @get("map").plotStory calaisObj
            @trigger("updateDateRange")
        getYahooNews: (query, start, done) ->
            cc "Getting Yahoo " + query + " " + start
            if !query? then return false
            self = @
            $.get "./get_yahoo_news.php",
                q: query.toLowerCase()
                start: start
            , (data) ->
                response = JSON.parse(data)
                cc response.bossresponse
                if response? and response.bossresponse? and response.bossresponse.news?
                    stories = response.bossresponse.news.results
                else if done? then done query, 0 , null
                _.each stories, (story) ->
                    self.getCalaisData story, story.title + story.abstract, self.formCalaisAndPlot
                cc start
                # 1000 is the length of results returned by Yahoo, so once we hit that, execute any callback for new data
                if start <= 1000
                    self.getYahooNews query, start + 50, done
                else if done? then done query, 0, null
        getCalaisData: (story, story_string, callback) ->
            self = @
            console.log "getting data"
            # Pass the title and the story body into calais
            $.get "./calais.php",
                content: story_string
            , (data) ->
                # parse the response object
                calaisjson = JSON.parse(data)
                unless calaisjson? then return
                # Check each property of the returned calais object
                for i of calaisjson
                  # If it contains a "resolutions" key, it has latitude and longitude
                  if calaisjson[i].hasOwnProperty("resolutions") then callback(story, calaisjson, i)
                return
            @
        filterByDate: (lodate, hidate) ->
            outofbounds = _.reject @get("articles").models, (article) ->
                date = article.get("date").getTime()
                cc date
                date <= hidate and date >= lodate
            cc outofbounds


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

    ### Router ###
    window.Workspace = Backbone.Router.extend
        routes:
            "saved": "saved"
            "settings": "settings"
            "play": "play"
            "map/:index/(:subview)": "goto"
        goto: ->
            cc arguments
        saved: ->
            cc "showing all maps"
            cc Backbone.history.fragment
        settings: ->
            cc "showing settings"
        play: ->
            cc "playing timeline animation"

    window.app = new window.Workspace()

    Backbone.history.start()