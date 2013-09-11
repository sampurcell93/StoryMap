$ ->
    # Quick logging
    window.cc = (arg) ->
        console.log arg

    window.home = "./"

    StoryMap = Backbone.Model.extend
        url: '/map'
        defaults: ->
            markers: []
            map: new GoogleMap @


    Maps = Backbone.Collection.extend
        url: 'maps.php'


    AllMaps = new Maps()
    AllMaps.fetch 
        success: (collection, response) ->
            collection.add new StoryMap()
        error: (collection, response) ->
            cc response