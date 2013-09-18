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

        # A function that issues a request to a curl script, retrieving google news stories
        getGoogleNews: (val, start) ->
            if !val? then return false
            self = @
            # cc "./getnews.php?q=" + val + "&start=" + start
            $.get "./getnews.php",
                q: val.toLowerCase()
                start: start
            , (data) ->
                # parse the json
                json = JSON.parse(data)
                cc json
                if json.responseDetails is "out of range start"
                  return false
                # Get location data from OpenCalais for each story item
                for i in [0...json.responseData.results.length]
                  self.getCalaisData json.responseData.results[i]
            true

        getCalaisData: (content) ->
            self = @
            console.log "getting data"
            # Pass the title and the story body into calais
            context = content.titleNoFormatting + content.content
            $.get "./calais.php",
                content: context
            , (data) ->
                # parse the response object
                json = JSON.parse(data)
                unless json? then return
                # Check each property of the returned calais object
                for el of json
                  # If it contains a "resolutions" key, it has latitude and longitude
                  if json[el].hasOwnProperty("resolutions")
                    content.latitude = json[el].resolutions[0].latitude
                    content.longitude = json[el].resolutions[0].longitude
                    # Set the date in order to make the range slider
                    content.date = new Date json.doc.info.docDate
                    # It's a valid story - push it
                    self.get("articles").add new models.Article(content)
                    # Plot the story en el mapa
                    self.get("map").plotStory content
                self.trigger("updateDateRange")
                return
            content

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