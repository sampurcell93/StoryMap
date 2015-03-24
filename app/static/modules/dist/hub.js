(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(function() {
    var App, app;
    App = (function(_super) {
      __extends(App, _super);

      function App() {
        return App.__super__.constructor.apply(this, arguments);
      }

      App.prototype.initialize = function(options) {};

      return App;

    })(Marionette.Application);
    app = new App;
    app.addRegions({
      "mapWrapper": "#all-map-wrapper",
      "feedLoaderWrapper": "#all-feed-loaders"
    });
    app.vent.dispatch = app.vent.trigger;
    app.dispatcher = app.vent;
    return app;
  });

}).call(this);
