({
    baseUrl: "./app/static/modules",
    waitSeconds: 15,
    // urlArgs : "bust="+ new Date().getTime(),
    paths: {
        "backbone"      : "dist/bower_components/backbone/backbone",
        "underscore"    : "dist/bower_components/underscore/underscore-min",
        "jquery"        : "dist/bower_components/jquery/dist/jquery.min",
        "jqueryUI"        : "dist/jquery-ui.min",
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
        "sweetalert"    : "dist/bower_components/sweetalert/lib/sweet-alert"
    },
    name: "app",
    out: "./app/static/modules/app-built.js"

})
