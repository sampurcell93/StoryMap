define ->
    class App extends Marionette.Application
        initialize: (options) ->

    app = new App

    app.addRegions({
        "mapWrapper": "#all-map-wrapper"
        "feedLoaderWrapper": "#all-feed-loaders"
    });

    app.vent.dispatch = app.vent.trigger;
    app.dispatcher = app.vent
    app