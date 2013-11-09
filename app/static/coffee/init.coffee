$ ->

    user = window.user = new window.models.User id: window.userid
    user.fetch({
        success: (model) ->
            cc model
            # Instantiate new collection of all maps
            AllMaps = window.AllMaps = new collections.Maps()
            AllMapsView = new window.views.MapInstanceList collection: AllMaps, user: user
            AllMaps.add new models.StoryMap()
        })

    $.post "/favorite", {
        user_id: 4
        query_id: 22
        }, (resp)->
            console.log resp