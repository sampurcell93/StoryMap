$ ->
    # Quick logging
    window.cc = (arg) ->
        console.log arg

    ### Data Models ###
    Article = Backbone.Model.extend()
    Articles = Backbone.Collection.extend
        model: Article
        initialize: (opts) ->
            # If the collection is the child of a news map, save a reference to the map
            if opts? and opts.parent_map then @parent_map = opts.parent_map
            @

    # Model for a single instance of a map, including all of the settings for the GMap,
    # the markers, and a collection of articles
    StoryMap = Backbone.Model.extend
        defaults: ->
            markers: []
            map: new GoogleMap @
            articles: new Articles parent_map: @
        # A function that issues a request to a curl script, retrieving google news stories
        getGoogleNews = (val, start) ->
          # cc "./getnews.php?q=" + val + "&start=" + start
          $.get "./getnews.php",
            q: val || $search.val()
            start: start
          , (data) ->
            # parse the json
            json = JSON.parse(data)
            if json.responseDetails is "out of range start"
              end = true
              return false
            # Get location data from OpenCalais for each story item
            for i in [0...json.responseData.results.length]
              getCalaisData json.responseData.results[i]
            true

        getCalaisData = (content) ->
          console.log "getting data"
          # Pass the title and the story body into calais
          context = content.titleNoFormatting + content.content
          $.get "./calais.php",
            content: context
          , (data) ->
            # parse the response object
            json = JSON.parse(data)
            unless json? then return
            console.log(json.doc.info.docDate)
            # Check each property of the returned calais object
            for el of json
              # If it contains a "resolutions" key, it has latitude and longitude
              if json[el].hasOwnProperty("resolutions")
                content.latitude = json[el].resolutions[0].latitude
                content.longitude = json[el].resolutions[0].longitude
                # It's a valid story - push it
                stories.push content
                # Plot the story en el mapa
                StoryMap.plotStory content
                return
          content

    # The global collection of all maps for a user, 
    # retrieved at runtime by the "Fetch" method, below
    Maps = Backbone.Collection.extend
        url: 'maps.php'
        model: StoryMap

    # Instantiate new collection of all maps
    AllMaps = new Maps()
    # Get all existing maps from server
    AllMaps.fetch 
        success: (collection, response) ->
            if collection.length is 0
                collection.add new StoryMap()
            else 
                cc "Now we want to go to the route for all saved maps"

        error: (collection, response) ->
            cc response

    ### Router ###
    Workspace = Backbone.Router.extend
        routes:
            "saved": "saved"
            "settings": "settings"
            "play": "play"
        saved: ->
            cc "showing all maps"
        settings: ->
            cc "showing settings"
        play: ->
            cc "playing timeline animation"

    app = new Workspace()

    Backbone.history.start()