(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define("user", ["hub"], function(hub) {
    var Preferences, PreferencesView, User, _user;
    Preferences = (function(_super) {
      __extends(Preferences, _super);

      function Preferences() {
        return Preferences.__super__.constructor.apply(this, arguments);
      }

      Preferences.prototype.defaults = function() {
        return {
          activeFeeds: ["google", "feedzilla"],
          inactiveFeeds: [],
          date_format: "MMM Do, YYYY"
        };
      };

      return Preferences;

    })(Backbone.Model);
    PreferencesView = (function(_super) {
      __extends(PreferencesView, _super);

      function PreferencesView() {
        return PreferencesView.__super__.constructor.apply(this, arguments);
      }

      PreferencesView.prototype.template = $("#preferences-view").html();

      PreferencesView.prototype.initialize = function() {
        return this.render();
      };

      PreferencesView.prototype.render = function() {
        console.log(this.model.toJSON());
        this.$el.html(_.template(this.template)(this.model.toJSON()));
        return this;
      };

      PreferencesView.prototype.events = {
        "click .js-save-preferences": function() {
          return console.log("saving!!");
        }
      };

      return PreferencesView;

    })(Backbone.View);
    User = (function(_super) {
      __extends(User, _super);

      function User() {
        return User.__super__.constructor.apply(this, arguments);
      }

      User.prototype.parse = function(r) {
        r.last_login = moment(r.last_login);
        return r;
      };

      User.prototype.defaults = function() {
        return {
          preferences: new Preferences()
        };
      };

      User.prototype.getActiveFeeds = function() {
        return this.get("preferences").get("activeFeeds");
      };

      User.prototype.setPreferences = function(prefs) {
        return this.set("preferences", new Preferences(prefs, {
          parse: true
        }));
      };

      return User;

    })(Backbone.Model);
    _user = new User;
    return {
      setActiveUser: function(user, prefs) {
        _user = new User(user, {
          parse: true
        });
        return _user.setPreferences(prefs);
      },
      getActiveUser: function() {
        return _user;
      },
      getPreferencesView: function(a, o) {
        return new PreferencesView(a, o);
      }
    };
  });

}).call(this);
