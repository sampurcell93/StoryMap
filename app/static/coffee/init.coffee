$ ->

    window.user = new window.models.User id: window.userid
    window.existingQueries = new window.collections.Queries()
    window.AllMaps = new collections.StoryMaps
    user.fetch({
        success: (model) ->
            existingQueries.fetch
                success: (coll) ->
                    console.log user.toJSON()
                    # Make a new map view/controller and render it
                    map = new models.StoryMap queries: existingQueries
                    AllMaps.add map
                    map.user = user
                    window.map = map = new views.MapItem model: map
                    map.render()
                    # Initialize routes
                    window.app = new window.Workspace({user: user, controller: map})
                    Backbone.history.start()
        })