$ ->
    window.user = new window.models.User id: window.userid
    window.existingQueries = new window.collections.Queries()
    existingQueries._byTitle = {}
    window.mapObj = new window.GoogleMap
    query = new models.Query
    window.map = new views.MapItem model: query
    # launchModal "<h2>loading....</h2>", {close: false}
    user.fetch({
        success: (model) ->
            existingQueries.fetch
                success: (coll) ->
                    destroyModal()
                    query.user = user
                    _.each coll.models, (query) ->
                        existingQueries._byTitle[query.get("title")] = query
                    # Make a new map view/controller and render it
                    map.render()
                    # Initialize routes
                    window.app = new window.Workspace({user: user, controller: map})
                    Backbone.history.start()
        })
