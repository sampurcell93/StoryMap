$ ->
    # Quick logging
    window.cc = (arg) ->
        console.log arg

    StoryMap = Backbone.Model.extend
        url: '/map'
        defaults: ->
            markers: []
            map: new GoogleMap @


    Maps = Backbone.Collection.extend
        url: './maps.php'
        model: StoryMap


    AllMaps = new Maps()
    cc "fethc"
    AllMaps.fetch 
        success: (collection, response) ->
            cc "success"
            collection.add new StoryMap()
        error: (collection, response) ->
            cc "fail"
            cc response