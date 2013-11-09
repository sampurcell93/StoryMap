$ ->

    window.models.User = Backbone.Model.extend
        url: ->
            "/users/" + @get("id")
        parse: (response) ->
            response.user.last_login = new Date response.user.last_login 
            response.user

