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
            launchModal "All Saved Maps", { destroyHash: true }

        settings: ->
            cc "showing settings"
            launchModal "Your Settings", { destroyHash: true }

    window.app = new window.Workspace()
    Backbone.history.start()