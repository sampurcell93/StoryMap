(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(["hub", "dist/typeahead", "dist/loaders", "modals", "queries", "stories", "map", "user", "sweetalert", "timeline"], function(hub, typeahead, loaders, Modal, queries, stories, maps, user, sweet, timeline) {
    var EntryWayView, dispatcher, entryWay, lFactory, tl, toggleSideBar, toggleSidebarAnimation;
    lFactory = new loaders();
    dispatcher = hub.dispatcher;
    EntryWayView = (function(_super) {
      __extends(EntryWayView, _super);

      function EntryWayView() {
        return EntryWayView.__super__.constructor.apply(this, arguments);
      }

      EntryWayView.prototype.el = "#entryway-view";

      EntryWayView.prototype.toggleViewState = function() {
        if (this.isModal === true) {
          return this.morphToTopBar();
        } else {
          return this.morphToModal();
        }
      };

      EntryWayView.prototype.initialize = function() {
        this.bindTypeahead();
        this.isModal = true;
        return this.listenTo(dispatcher, "render:topbar", this.morphToTopBar);
      };

      EntryWayView.prototype.morphToModal = function() {
        this.isModal = true;
        return this.$el.removeClass("top-bar");
      };

      EntryWayView.prototype.morphToTopBar = function(query) {
        if (query != null) {
          this.$('#js-make-query').typeahead('val', query);
        }
        this.$("#js-make-query").blur();
        if (this.isModal === false) {
          return this;
        }
        this.isModal = false;
        this.$el.addClass("top-bar");
        this.$("#save-active-query").fadeIn("fast").attr("disabled", false);
        return this;
      };

      EntryWayView.prototype.hideSaveButton = function() {
        this.$("#save-active-query").fadeOut("fast").attr("disabled", true);
        return this;
      };

      EntryWayView.prototype.bindTypeahead = function() {
        return new queries.QueryAutoComplete(this.$("#js-make-query"));
      };

      EntryWayView.prototype.showSaved = function() {
        var m;
        m = new Modal({
          content: [queries.getHelpString(), queries.getSavedQueriesList()]
        });
        return m.launch();
      };

      EntryWayView.prototype.showPreferences = function() {
        var m;
        m = new Modal({
          content: user.getPreferencesView({
            model: user.getActiveUser()
          }).el
        });
        return m.launch();
      };

      EntryWayView.prototype.showHelp = function() {
        var m;
        m = new Modal({
          content: _.template($("#help-template").html())()
        });
        m.launch();
        return m.$el.css("top", 320 + "px");
      };

      EntryWayView.prototype.events = {
        "click .js-saved": "showSaved",
        "click .js-preferences": "showPreferences",
        "click .js-help": "showHelp",
        "click #save-active-query": function(e) {
          var $t, query, request, saveSuccess, spinner;
          spinner = $(lFactory.get("spinner"));
          saveSuccess = function(title) {
            dispatcher.dispatch("navigate", "existing/" + title, {
              replace: true,
              trigger: false
            });
            spinner.remove();
            return swal({
              title: "Saved!",
              text: "You saved this query! You can look at it any time, and we'll be updating it in the background.",
              allowOutsideClick: true,
              type: "success",
              confirmButtonText: "OK",
              timer: 4500
            });
          };
          $t = $(e.currentTarget);
          query = queries.getActiveQuery();
          $t.append(spinner);
          request = queries.createRequest(query.get("title"));
          return request.doesExist((function(_this) {
            return function(response) {
              return query != null ? query.favorite().success(function() {
                var allStories;
                if (response.exists === false) {
                  allStories = query.get("stories");
                  return allStories.create().success(function() {
                    return saveSuccess(query.get("title"));
                  });
                } else {
                  return saveSuccess(query.get("title"));
                }
              }) : void 0;
            };
          })(this));
        }
      };

      return EntryWayView;

    })(Backbone.View);
    entryWay = new EntryWayView();
    tl = null;
    $(".js-filter-stories").keyup(function(e) {
      var activeStories, filterer, key, val;
      val = $(this).val();
      key = e.keyCode || e.which;
      activeStories = stories.getActiveSet();
      if ((activeStories != null) && key !== 32) {
        filterer = new stories.StoryFilter(activeStories);
        return filterer.filter(val);
      }
    });
    $("nav").on("click", function() {
      if ($(window).width() < 1184) {
        return $(this).toggleClass("showing-menu");
      }
    });
    toggleSidebarAnimation = function(count, map) {
      var frame;
      if (map != null) {
        google.maps.event.trigger(map, 'resize');
        map.setZoom(map.getZoom());
        frame = requestAnimationFrame(function() {
          return toggleSidebarAnimation(++count, map);
        });
      }
      if (count > 100 || (map == null)) {
        return cancelAnimationFrame(frame);
      }
    };
    toggleSideBar = function(dir) {
      var $fullSize, map, _ref;
      $fullSize = $(".shift-to-full, .top-bar, .all-stories");
      if (dir === "show") {
        $fullSize.removeClass("away fullsize");
      } else if (dir === "hide") {
        $fullSize.addClass("away fullsize");
      } else {
        $fullSize.toggleClass("away").toggleClass("fullsize");
      }
      map = (_ref = maps.getActiveMap()) != null ? _ref.map : void 0;
      return toggleSidebarAnimation(0, map);
    };
    $(".js-toggle-view").click(function() {
      return toggleSideBar();
    });
    dispatcher.on("show:sidebars", function() {
      toggleSideBar("show");
      if (tl != null) {
        return tl.$el.slideDown("fast");
      }
    });
    dispatcher.on("add:feedLoader", function(name, loadingRequest) {
      var activeStories, group;
      if (loadingRequest != null) {
        activeStories = stories.getActiveSet();
        group = activeStories.getGroup(name);
        return loadingRequest.on("retrieval_" + name + ":done", (function(_this) {
          return function() {
            return group.analyze();
          };
        })(this));
      }
    });
    dispatcher.on("execute:query", function(q) {
      return entryWay.morphToTopBar();
    });
    dispatcher.on("destroy:timeline", function(query) {
      if (tl) {
        return tl.destroy();
      }
    });
    dispatcher.on("add:map", function(query) {
      var _ref;
      if (tl) {
        tl.destroy();
      }
      tl = new timeline.TimelineView({
        collection: query.get("stories"),
        map: (_ref = maps.getActiveMap()) != null ? _ref.map : void 0
      });
      return tl.reset().updateHandles(true).render();
    });
    return function() {};
  });

}).call(this);
