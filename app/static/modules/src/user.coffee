define ["hub"], (hub) ->

    class Preferences extends Backbone.Model
        defaults: ->
            return {
                activeFeeds: ["google", "yahoo" ]
                inactiveFeeds: []
                date_format: "MMM Do, YYYY"
            }

    class PreferencesView extends Backbone.View
        template: $("#preferences-view").html()
        initialize: ->
            do @render
        render: ->
            console.log @model.toJSON()
            @$el.html _.template(@template)(@model.toJSON());
            @
        events: 
            "click .js-save-preferences": ->
                console.log("saving!!");


    class User extends Backbone.Model
        parse: (r) ->
            r.last_login = moment(r.last_login);
            r
        defaults: ->
            return {
                preferences: new Preferences()
            }
        getActiveFeeds: -> @get("preferences").get("activeFeeds")
        setPreferences: (prefs) ->
            @set "preferences", new Preferences(prefs, {parse: true});

    _user = new User

    return {
        setActiveUser: (user, prefs) ->
            _user = new User(user, {parse: true});
            _user.setPreferences(prefs);
        getActiveUser: -> _user
        getPreferencesView: (a, o) -> new PreferencesView(a,o);
    }