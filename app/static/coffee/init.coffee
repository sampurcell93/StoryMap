$ ->

    user = new window.models.User id: window.userid
    window.existingQueries = new window.collections.Queries()
    user.fetch({
        success: (model) ->
            existingQueries.fetch
                success: (coll) ->
                    cc user.toJSON()
                    # Initialize routes
                    window.app = new window.Workspace({user: user})
                    Backbone.history.start()
                    # Make a new map view/controller and render it
                    map = new models.StoryMap queries: existingQueries
                    map.user = user
                    map = new views.MapItem model: map
                    map.render()
        })


    $.post "/favorite", {
        user_id: 56
        query_id: 21
    }, (resp) ->
        cc resp