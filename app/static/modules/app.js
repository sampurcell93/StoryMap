require.config({
    urlArgs: "?bust=" + Date.now(),
    paths: {
        "backbone"      : "dist/bower_components/backbone/backbone",
        "underscore"    : "dist/bower_components/underscore/underscore-min",
        "jquery"        : "dist/bower_components/jquery/dist/jquery.min",
        "jqueryUI"      : "dist/jquery-ui.min",
        "marionette"    : "dist/bower_components/marionette/lib/backbone.marionette.min",
        "moment"        : "dist/bower_components/moment/moment",
        "map"           : "dist/map",
        "stories"       : "dist/stories",
        "queries"       : "dist/queries",
        "timeline"      : "dist/timeline",
        "coreUI"        : "dist/coreUI",
        "hub"           : "dist/hub",
        "themes"        : "dist/themes",
        "modals"        : "dist/modal",
        "user"          : "dist/user",
        "router"        : "dist/router",
        "loaders"       : "dist/loaders",
        "typeahead"     : "dist/typeahead",
        "sweetalert"    : "dist/bower_components/sweetalert/lib/sweet-alert"
    }
});

define("app", ["jquery", "underscore", "backbone", "marionette", "moment", "jqueryUI"], function($, _, Backbone, Marionette, moment, jqueryUI) {
    require(["hub", "coreUI", "router", "map", "stories", "queries", "timeline", "user"], function(hub, coreUI, Router, map, stories, queries, timeline, user) {
        window.savedQueries = queries.setSavedQueries(window.savedQueries.queries || []);
        user.setActiveUser(window.user, window.prefs);
        var router = new Router();
        Backbone.history.start()
        coreUI.load();
        r = new timeline.DateRange()
        v = new timeline.TwoDatePicker(null, null, r);
        console.log(r)
    })
});

// require(["app"]);