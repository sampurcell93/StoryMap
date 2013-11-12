$ ->
    ### Router ###
    window.Workspace = Backbone.Router.extend
        initialize: (attrs) ->
            @user = attrs.user
        routes:
            "saved": "saved"
            "settings": "settings"
        saved: (rt) ->
            saved = new views.QueryThumbList collection: @user.get("queries")
            launchModal saved.render().el, { destroyHash: true }
        settings: ->
            launchModal "<h2>Your Settings</h2>", { destroyHash: true }
