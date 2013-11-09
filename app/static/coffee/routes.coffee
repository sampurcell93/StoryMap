$ ->
    ### Router ###
    window.Workspace = Backbone.Router.extend
        initialize: (attrs) ->
            @user = attrs.user
        routes:
            "saved": "saved"
            "settings": "settings"
        saved: (rt) ->
            settings = new views.QueryThumbList collection: @user.get("queries")
            launchModal settings.render().el, { destroyHash: true }
        settings: ->
            cc "showing settings"
            launchModal "<h2>Your Settings</h2>", { destroyHash: true }
