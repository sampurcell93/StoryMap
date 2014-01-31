$ ->
    ### Router ###
    window.Workspace = Backbone.Router.extend
        initialize: (attrs) ->
            @user = attrs.user
            @controller = attrs.controller
        routes:
            "saved": "saved"
            "settings": "settings"
            "query/:title": "gotomap"
            "help": "help"
        saved: (rt) ->
            saved = new views.QueryThumbList collection: @user.get("queries")
            launchModal saved.render().el, { destroyHash: true }
        settings: ->
            launchModal "<h2>Your Settings</h2>", { destroyHash: true }
        gotomap: (title) ->
            cc existingQueries._byTitle
            console.log @
            if existingQueries._byTitle.hasOwnProperty(title)
                @controller.loadQuery existingQueries._byTitle[title]
                $(".js-save-query").addClass("hidden")
        help: ->
            launchModal($("#help-template").html())