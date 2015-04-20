(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define("queries", ["hub", "stories", "map", "typeahead"], function(hub, stories, map) {
    var EmptyQueryItem, Queries, Query, QueryAutoComplete, QueryItem, QueryList, QueryRequest, StoryRetrievalCounter, dispatcher, searchEngine, _activeQuery, _savedQueries;
    _activeQuery = null;
    _savedQueries = null;
    dispatcher = hub.dispatcher;
    (function(_) {
      'use strict';
      return _.compile = function(templ) {
        var compiled;
        compiled = this.template(templ);
        compiled.render = function(ctx) {
          return this(ctx);
        };
        return compiled;
      };
    })(window._);
    searchEngine = new Bloodhound({
      local: window.tokens,
      datumTokenizer: function(d) {
        return Bloodhound.tokenizers.whitespace(d.val);
      },
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      limit: 30
    });
    searchEngine.initialize();
    QueryAutoComplete = (function() {
      function QueryAutoComplete(el) {
        var $searchbox;
        this.el = el;
        $searchbox = this.el;
        $searchbox.typeahead({
          hint: true,
          minLength: 1,
          highlight: true
        }, {
          source: searchEngine.ttAdapter(),
          displayKey: "val",
          templates: {
            empty: _.compile("<div class='tt-empty-results'>No results found.</div>"),
            suggestion: _.compile("<%= val %>")
          }
        }).on("typeahead:selected", (function(_this) {
          return function(e, suggestion) {
            dispatcher.dispatch("execute:query", suggestion.val, true);
            e.stopPropagation();
            return e.preventDefault();
          };
        })(this));
        this.bindEvents();
      }

      QueryAutoComplete.prototype.bindEvents = function() {
        return this.el.on("keydown", (function(_this) {
          return function(e) {
            var key;
            key = e.keyCode || e.which;
            if (key === 13) {
              return _this.query();
            }
          };
        })(this));
      };

      QueryAutoComplete.prototype.getCurrentInput = function() {
        return this.el.typeahead("val") || this.el.val();
      };

      QueryAutoComplete.prototype.query = function(force) {
        var query, request;
        if (force == null) {
          force = false;
        }
        query = this.getCurrentInput();
        request = new QueryRequest(query);
        if (force === true) {
          return dispatcher.dispatch("navigate", "fetch/" + query, true);
        } else {
          return request.doesExist(function(response) {
            if (response.exists === true) {
              return dispatcher.dispatch("navigate", "existing/" + query, true);
            } else {
              return dispatcher.dispatch("navigate", "fetch/" + query, true);
            }
          });
        }
      };

      return QueryAutoComplete;

    })();
    StoryRetrievalCounter = (function() {
      function StoryRetrievalCounter() {
        this.totalStoriesRetrieved = {};
        _.extend(this, Backbone.Events);
      }

      StoryRetrievalCounter.prototype.addToTotal = function(feed, incrementValue) {
        var totalStories;
        totalStories = this.totalStoriesRetrieved[feed];
        if (!totalStories) {
          this.totalStoriesRetrieved[feed] = {
            retrieved: incrementValue,
            analyzed: 0
          };
        } else {
          totalStories.retrieved += incrementValue;
        }
        return this.trigger("addedStories:" + feed);
      };

      StoryRetrievalCounter.prototype.getTotal = function(feed) {
        return this.totalStoriesRetrieved[feed];
      };

      return StoryRetrievalCounter;

    })();
    QueryRequest = (function() {
      function QueryRequest(title) {
        this.title = title;
        this.getNews = __bind(this.getNews, this);
        this.totalStoriesRetrieved = new StoryRetrievalCounter;
      }

      QueryRequest.prototype.fetchExistingQuery = function() {
        return $.getJSON("./queries/" + this.title, {}, function() {});
      };

      QueryRequest.prototype.external_url = './externalNews';

      QueryRequest.prototype.getNews = function(feed) {
        var fns;
        fns = {
          "google": this.getGoogleNews,
          "yahoo": this.getYahooNews,
          "feedzilla": this.getFeedZillaNews
        };
        return fns[feed].call(this);
      };

      QueryRequest.prototype.getGoogleNews = function(start, done) {
        var query;
        if (done == null) {
          done = function() {};
        }
        query = this.title;
        start = start || 0;
        return $.getJSON(this.external_url, {
          source: 'google',
          q: query.toLowerCase(),
          start: start,
          analyze: false
        }, (function(_this) {
          return function(responseStories) {
            _this.totalStoriesRetrieved.addToTotal("google", responseStories.length);
            stories.addToActiveSet(responseStories);
            debugger;
          };
        })(this)).fail((function(_this) {
          return function() {
            return console.log(arguments);
          };
        })(this)).always((function(_this) {
          return function() {
            _this.totalStoriesRetrieved.trigger("retrieval_google:done");
            if (done != null) {
              return done();
            }
          };
        })(this));
      };

      QueryRequest.prototype.getYahooNews = function(start, done) {
        var query;
        if (done == null) {
          done = function() {};
        }
        query = "\"" + (this.title.toLowerCase()) + "\"";
        start || (start = 0);
        return $.getJSON(this.external_url, {
          source: 'yahoo',
          q: query,
          start: start,
          analyze: false
        }, (function(_this) {
          return function(responseStories) {
            var total;
            if (responseStories == null) {
              _this.totalStoriesRetrieved.addToTotal("yahoo", responseStories != null ? responseStories.length : void 0);
              stories.addToActiveSet(responseStories);
            }
            total = 60;
            return _this;
          };
        })(this)).fail((function(_this) {
          return function() {
            return console.log(arguments);
          };
        })(this)).always((function(_this) {
          return function() {
            _this.totalStoriesRetrieved.trigger("retrieval_yahoo:done");
            return done();
          };
        })(this));
      };

      QueryRequest.prototype.getFeedZillaNews = function(done) {
        if (done == null) {
          done = function() {};
        }
        return $.getJSON(this.external_url, {
          q: this.title,
          source: 'feedzilla',
          analyze: false
        }, (function(_this) {
          return function(responseStories) {
            console.log(responseStories);
            _this.totalStoriesRetrieved.addToTotal("feedzilla", responseStories.length);
            stories.addToActiveSet(responseStories);
            debugger;
          };
        })(this)).fail((function(_this) {
          return function() {
            return console.log(arguments);
          };
        })(this)).always((function(_this) {
          return function() {
            _this.totalStoriesRetrieved.trigger("retrieval_feedzilla:done");
            return done();
          };
        })(this));
      };

      QueryRequest.prototype.doesExist = function(done) {
        if (done == null) {
          done = function() {};
        }
        return $.getJSON("./queryExists/" + this.title, {}, (function(_this) {
          return function() {
            return done.apply(_this, arguments);
          };
        })(this));
      };

      return QueryRequest;

    })();
    Query = (function(_super) {
      __extends(Query, _super);

      function Query() {
        return Query.__super__.constructor.apply(this, arguments);
      }

      Query.prototype.defaults = function() {
        return {
          title: "",
          created: moment(),
          stories: new stories.Stories()
        };
      };

      Query.prototype.initialize = function() {
        var _ref;
        return (_ref = this.get("stories")) != null ? _ref.query = this : void 0;
      };

      Query.prototype.parse = function(resp) {
        resp.created = moment(resp.created);
        resp.last_query = moment(resp.last_query);
        if ((resp.stories != null) && resp.stories instanceof stories.Stories === false) {
          resp.stories = new stories.Stories(resp.stories, {
            parse: true
          });
        }
        return resp;
      };

      Query.prototype.favorite = function() {
        var query_id, _ref;
        if ((_ref = window.savedQueries) != null) {
          _ref.add(this);
        }
        query_id = this.id || this.get("id");
        return $.post("./favorite", {
          query_id: query_id,
          name: this.get("title")
        }, (function(_this) {
          return function(resp) {
            try {
              resp = JSON.parse(resp);
            } catch (_error) {}
            if (resp.id != null) {
              _this.id = resp.id;
              return _this.set("id", resp.id);
            }
          };
        })(this));
      };

      return Query;

    })(Backbone.Model);
    Queries = (function(_super) {
      __extends(Queries, _super);

      function Queries() {
        return Queries.__super__.constructor.apply(this, arguments);
      }

      Queries.prototype.model = Query;

      Queries.prototype.comparator = function(m) {
        return -m.get("last_query");
      };

      return Queries;

    })(Backbone.Collection);
    EmptyQueryItem = (function(_super) {
      __extends(EmptyQueryItem, _super);

      function EmptyQueryItem() {
        return EmptyQueryItem.__super__.constructor.apply(this, arguments);
      }

      EmptyQueryItem.prototype.template = "#empty-query-item";

      EmptyQueryItem.prototype.className = 'center';

      EmptyQueryItem.prototype.tagName = 'li';

      return EmptyQueryItem;

    })(Marionette.ItemView);
    QueryItem = (function(_super) {
      __extends(QueryItem, _super);

      function QueryItem() {
        return QueryItem.__super__.constructor.apply(this, arguments);
      }

      QueryItem.prototype.template = "#query-item";

      QueryItem.prototype.tagName = "li";

      QueryItem.prototype.initialize = function() {
        return this.listenTo(this.model, {
          "unfavorite": (function(_this) {
            return function() {
              _this.model.destroy();
              return _this.destroy();
            };
          })(this)
        });
      };

      QueryItem.prototype.events = {
        "click .js-load-map": function() {
          return window.destroyActiveModal((function(_this) {
            return function() {
              return dispatcher.dispatch("navigate", "existing/" + (_this.model.get("title")), true);
            };
          })(this));
        },
        "click .js-remove-query": function() {
          return $.post("./unfavorite", {
            id: this.model.id
          }, (function() {}), 'json').success((function(_this) {
            return function() {
              return _this.model.trigger("unfavorite");
            };
          })(this)).error((function(_this) {
            return function() {
              return swal({
                type: "error",
                title: "Error",
                text: "Something went wrong deleting this story. Try again.",
                timer: 5000
              });
            };
          })(this));
        }
      };

      return QueryItem;

    })(Marionette.ItemView);
    QueryList = (function(_super) {
      __extends(QueryList, _super);

      function QueryList() {
        return QueryList.__super__.constructor.apply(this, arguments);
      }

      QueryList.prototype.childView = QueryItem;

      QueryList.prototype.emptyView = EmptyQueryItem;

      QueryList.prototype.tagName = 'ul';

      QueryList.prototype.className = 'saved-queries-list';

      return QueryList;

    })(Marionette.CollectionView);
    return {
      createRequest: function(query) {
        var request;
        return request = new QueryRequest(query);
      },
      setActiveQuery: function(query) {
        return _activeQuery = new Query(query, {
          parse: true
        });
      },
      getActiveQuery: function() {
        return _activeQuery;
      },
      setSavedQueries: function(queries) {
        _savedQueries = new Queries(queries, {
          parse: true
        });
        _savedQueries.sort();
        return _savedQueries;
      },
      getSavedQueriesList: function() {
        var list;
        list = new QueryList({
          collection: _savedQueries
        });
        return list.render().el;
      },
      getHelpString: function() {
        return _.template($("#query-list-help").html())();
      },
      QueryAutoComplete: QueryAutoComplete
    };
  });

}).call(this);
