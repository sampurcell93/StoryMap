(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define("router", ["hub", "queries", "loaders", "stories", "timeline", "user", "map"], function(hub, queries, loaders, stories, timeline, user, map) {
    var Controller, ProgressBarUpdater, Router, dispatcher, _activeFeeds;
    dispatcher = hub.dispatcher;
    _activeFeeds = user.getActiveUser().getActiveFeeds();
    loaders = new loaders();
    ProgressBarUpdater = (function() {
      function ProgressBarUpdater() {
        this.finishedRetrievingCount = 0;
        this.finishedAnalysisCount = 0;
        this.totalStoriesBeingAnalyzed = 0;
        this.currentProgressBarVal = .1;
        this.progressBar = loaders.get("generic");
        this.progressBar.el = $("#overall-progress");
        this.progressBar.number = $("#overall-progress-number");
        this.hideBar();
        _.extend(this, Backbone.Events);
      }

      ProgressBarUpdater.prototype.hideBar = function() {
        return this.progressBar.hide();
      };

      ProgressBarUpdater.prototype.showBar = function() {
        return this.progressBar.show();
      };

      ProgressBarUpdater.prototype._done = function() {
        this.stopListening(this.collection);
        this.hideBar();
        dispatcher.dispatch("render:timeline");
        return this.done.call(this);
      };

      ProgressBarUpdater.prototype.done = function() {};

      ProgressBarUpdater.prototype.listenToAnalysisProgress = function() {
        if (this.collection == null) {
          console.error("ProgressBarUpdater needs a collection to listen to.");
          return this;
        }
        this.listenTo(this.collection, "done:analysis", (function(_this) {
          return function() {
            var newVal;
            _this.finishedAnalysisCount++;
            newVal = _this.currentProgressBarVal + ((_this.finishedAnalysisCount / _this.totalStoriesBeingAnalyzed) * 100);
            _this.progressBar.set(newVal);
            console.log(newVal);
            if (newVal >= 95) {
              return _this._done();
            }
          };
        })(this));
        return this;
      };

      ProgressBarUpdater.prototype.listenToRetrievalProgress = function(retrievalObj, feed, len, next, first) {
        if (next == null) {
          next = null;
        }
        if (first == null) {
          first = false;
        }
        if (first === true && !this.progressBar.finalStage) {
          this.progressBar.setText("Getting news stories from " + feed + "...");
        }
        return this.listenToOnce(retrievalObj, "retrieval_" + feed + ":done", (function(_this) {
          return function() {
            var _ref;
            _this.progressBar.setText("Done getting stories from " + feed + "...");
            setTimeout(function() {
              var activeStories;
              if (next != null) {
                return _this.progressBar.setText("Getting news stories from " + next + "...");
              } else {
                _this.progressBar.finalStage = true;
                _this.progressBar.setText("Analyzing news stories for location...");
                dispatcher.dispatch("analyze", feed);
                activeStories = stories.getActiveSet();
                return activeStories.analyze();
              }
            }, 1000);
            _this.totalStoriesBeingAnalyzed += ((_ref = retrievalObj.totalStoriesRetrieved[feed]) != null ? _ref.retrieved : void 0) || 0;
            _this.finishedRetrievingCount++;
            return _this.progressBar.set((_this.finishedRetrievingCount / len * 100) * .2);
          };
        })(this));
      };

      ProgressBarUpdater.prototype.destroy = function() {
        return this.stopListening();
      };

      return ProgressBarUpdater;

    })();
    Controller = (function(_super) {
      __extends(Controller, _super);

      function Controller() {
        this.executeQuery = __bind(this.executeQuery, this);
        return Controller.__super__.constructor.apply(this, arguments);
      }

      Controller.prototype.registerListeners = function(from) {
        from.on("execute:query", this.executeQuery);
        this.progressUpdater = new ProgressBarUpdater();
        return this.progressUpdater.done = function() {
          var tl;
          dispatcher.dispatch("destroy:timeline");
          tl = new timeline.TimelineView({
            collection: this.collection,
            map: map.getActiveMap().map
          });
          tl.reset().updateHandles(true).render();
          return this.trigger("done");
        };
      };

      Controller.prototype.executeQuery = function(query, exists) {
        if (exists === true) {
          return this.router.navigate("existing/" + query, true);
        } else {
          return this.router.navigate("fetch/" + query, true);
        }
      };

      Controller.prototype.renderExistingQueries = function(queries) {
        return this.renderExistingQuery(queries);
      };

      Controller.prototype.renderExistingQuery = function(query) {
        var promise, request;
        request = queries.createRequest(query);
        promise = request.fetchExistingQuery();
        return promise.success((function(_this) {
          return function(response) {
            _this.progressUpdater.hideBar();
            dispatcher.dispatch("render:topbar", query);
            query = queries.setActiveQuery(response);
            dispatcher.dispatch("add:map", query);
            dispatcher.dispatch("render:timeline");
            dispatcher.dispatch("show:sidebars");
            dispatcher.dispatch("clear:map");
            stories.setActiveStories(query.get("stories"));
            return destroyActiveModal();
          };
        })(this)).error(function() {
          return console.log("error fetching existing");
        });
      };

      Controller.prototype.fetchNewQuery = function(query) {
        var activeStorySet, q, request;
        this.progressUpdater.destroy();
        this.progressUpdater = new ProgressBarUpdater(query);
        this.progressUpdater.showBar();
        activeStorySet = new stories.Stories();
        q = queries.setActiveQuery({
          title: query,
          stories: activeStorySet
        });
        dispatcher.dispatch("add:map", q);
        dispatcher.dispatch("show:sidebars");
        dispatcher.dispatch("clear:map");
        stories.setActiveStories(activeStorySet);
        this.progressUpdater.collection = activeStorySet;
        this.progressUpdater.listenToAnalysisProgress();
        request = queries.createRequest(query, activeStorySet);
        return request.doesExist((function(_this) {
          return function(response) {
            var retrievalObj;
            if (response.exists === true) {
              return _this.router.navigate("existing/" + query, true);
            } else {
              retrievalObj = request.totalStoriesRetrieved;
              _.each(_activeFeeds, function(feed, i) {
                return setTimeout(function() {
                  var first, next;
                  next = _activeFeeds[i + 1];
                  first = i === 0 ? true : false;
                  _this.progressUpdater.listenToRetrievalProgress(retrievalObj, feed, _activeFeeds.length, next, first);
                  return request.getNews(feed);
                }, 300 * i);
              });
              dispatcher.dispatch("render:topbar", query);
              return destroyActiveModal();
            }
          };
        })(this));
      };

      return Controller;

    })(Marionette.Controller);
    Router = (function(_super) {
      __extends(Router, _super);

      function Router() {
        return Router.__super__.constructor.apply(this, arguments);
      }

      Router.prototype.initialize = function() {
        this.controller = new Controller;
        this.controller.router = this;
        this.controller.registerListeners(hub.dispatcher);
        return hub.dispatcher.on("navigate", (function(_this) {
          return function(route, opts) {
            return _this.navigate(route, opts);
          };
        })(this));
      };

      Router.prototype.appRoutes = {
        "existing/*splat": "renderExistingQueries",
        "fetch/:query": "fetchNewQuery"
      };

      return Router;

    })(Marionette.AppRouter);
    return Router;
  });

}).call(this);
