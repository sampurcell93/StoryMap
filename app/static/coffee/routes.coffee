$ ->
    ### Router ###
    window.Workspace = Backbone.Router.extend
        routes:
            "saved": "saved"
            "settings": "settings"
            "map/:index/(:subview)": "goto"
        goto: ->
            cc arguments
        saved: (rt) ->
            cc "showing all maps"   
            launchModal "<h2>All Saved Maps</h2>", { destroyHash: true }

        settings: ->
            cc "showing settings"
            launchModal "<h2>Your Settings</h2>", { destroyHash: true }

    window.app = new window.Workspace()
    Backbone.history.start()