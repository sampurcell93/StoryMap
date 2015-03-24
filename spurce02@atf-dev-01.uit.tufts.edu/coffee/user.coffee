$ ->

    window.models.User = Backbone.Model.extend
        url: ->
            "/users/" + @get("id")
        parse: (response) ->
            cc "parsing"
            response.user.last_login = new Date response.user.last_login 
            queries = new collections.Queries
            _.each response.user.queries, (query) ->
                queries.add new models.Query(query)
            response.user.queries = queries
            response.user

