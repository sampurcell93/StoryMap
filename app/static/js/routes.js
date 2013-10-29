// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    /* Router*/

    window.Workspace = Backbone.Router.extend({
      routes: {
        "saved": "saved",
        "settings": "settings",
        "map/:index/(:subview)": "goto"
      },
      goto: function() {
        return cc(arguments);
      },
      saved: function(rt) {
        cc("showing all maps");
        return launchModal("<h2>All Saved Maps</h2>", {
          destroyHash: true
        });
      },
      settings: function() {
        cc("showing settings");
        return launchModal("<h2>Your Settings</h2>", {
          destroyHash: true
        });
      }
    });
    window.app = new window.Workspace();
    return Backbone.history.start();
  });

}).call(this);
