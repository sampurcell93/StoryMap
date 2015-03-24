(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(["hub", "modals"], function(hub, Modal) {
    var GeoCoder, GeoCoderView, GeoList, GeoListItem, QuickStory, Stories, Story, StoryAnalyzer, StoryFilter, StoryItem, StoryList, dispatcher, stripHTML, _activeStories, _activeStoryList;
    _activeStories = null;
    dispatcher = hub.dispatcher;
    stripHTML = function() {
      var div;
      div = document.createElement("div");
      div.innerHTML = this;
      return div.innerText;
    };
    Story = (function(_super) {
      __extends(Story, _super);

      function Story() {
        return Story.__super__.constructor.apply(this, arguments);
      }

      Story.prototype.url = function() {
        var url;
        url = "./stories";
        if (this.id) {
          url += "/" + this.id;
        }
        return url;
      };

      Story.prototype.defaults = function() {
        return {
          url: "#"
        };
      };

      Story.prototype.parse = function(response) {
        response.date = moment(response.date);
        response.created = moment(response.created);
        return response;
      };

      Story.prototype.hasCoordinates = function() {
        return (this.get("lat") != null) && (this.get("lng") != null);
      };

      Story.prototype.hasLocation = function() {
        return (this.lat != null) && (this.lng != null);
      };

      return Story;

    })(Backbone.Model);
    GeoCoder = (function() {
      function GeoCoder(address) {
        this.address = address;
      }

      GeoCoder.prototype.geocodeUrl = 'http://maps.googleapis.com/maps/api/geocode/json?sensor=true&address=';

      GeoCoder.prototype.geocode = function() {
        return $.getJSON(this.geocodeUrl + encodeURIComponent(this.address));
      };

      return GeoCoder;

    })();
    GeoListItem = (function(_super) {
      __extends(GeoListItem, _super);

      function GeoListItem() {
        return GeoListItem.__super__.constructor.apply(this, arguments);
      }

      GeoListItem.prototype.tagName = 'li';

      GeoListItem.prototype.template = "#geocode-choice";

      GeoListItem.prototype.chooseLocation = function() {
        var targetStory;
        targetStory = this.model.collection.story;
        return targetStory.save({
          lat: this.model.get("geometry").location.lat,
          lng: this.model.get("geometry").location.lng,
          location: this.model.get("formatted_address")
        }, {
          success: (function(_this) {
            return function() {
              targetStory.trigger("find", targetStory);
              window.destroyActiveModal();
              return dispatcher.dispatch("plot:story", targetStory);
            };
          })(this),
          error: (function(_this) {
            return function() {
              return console.log(arguments);
            };
          })(this)
        });
      };

      GeoListItem.prototype.events = {
        "click": "chooseLocation"
      };

      return GeoListItem;

    })(Marionette.ItemView);
    GeoList = (function(_super) {
      __extends(GeoList, _super);

      function GeoList() {
        return GeoList.__super__.constructor.apply(this, arguments);
      }

      GeoList.prototype.childView = GeoListItem;

      return GeoList;

    })(Marionette.CollectionView);
    GeoCoderView = (function(_super) {
      __extends(GeoCoderView, _super);

      function GeoCoderView() {
        return GeoCoderView.__super__.constructor.apply(this, arguments);
      }

      GeoCoderView.prototype.enterLocTemplate = _.template($("#enter-loc").html() || "");

      GeoCoderView.prototype.render = function() {
        this.$el.html(this.enterLocTemplate(this.model.toJSON()));
        return this;
      };

      GeoCoderView.prototype.fetchLocations = function(address) {
        var geocoder;
        geocoder = new GeoCoder(address);
        return geocoder.geocode().success((function(_this) {
          return function(response) {
            var collection;
            collection = new Backbone.Collection(response.results);
            collection.story = _this.model;
            return new GeoList({
              el: _this.$(".geocode-choices"),
              model: _this.model,
              collection: collection
            }).render();
          };
        })(this)).error(function() {});
      };

      GeoCoderView.prototype.events = {
        "click .js-geocode-go": function() {
          var input;
          input = this.$(".js-address-value").val();
          if (input) {
            return this.fetchLocations(input);
          }
        },
        "keydown .js-address-value": function(e) {
          var $t;
          $t = $(e.currentTarget);
          if ($t.val() && e.keyCode === 13) {
            return this.fetchLocations($t.val());
          }
        }
      };

      return GeoCoderView;

    })(Backbone.View);
    StoryFilter = (function() {
      function StoryFilter(collection) {
        this.collection = collection;
      }

      StoryFilter.prototype.filterFns = {
        "location": function(story) {
          return story.get("lat") !== null && story.get("lng") !== null;
        },
        "nolocation": function(story) {
          return story.get("lat") === null && story.get("lng") === null;
        },
        "favorite": function(story) {
          return false;
        },
        "google": function(story) {
          return story.get("aggregator") === "google";
        },
        "yahoo": function(story) {
          return story.get("aggregator") === "yahoo";
        }
      };

      StoryFilter.prototype.filter = function(val) {
        val = val.toLowerCase().replace(" ", "");
        if (this.collection != null) {
          return this.collection.each(function(story) {
            var title, _ref;
            title = (_ref = story.get("title")) != null ? _ref.toLowerCase().replace(" ", "") : void 0;
            if (title.indexOf(val) === -1) {
              return story.trigger("hide");
            } else {
              return story.trigger("show");
            }
          });
        }
      };

      return StoryFilter;

    })();
    StoryAnalyzer = (function() {
      function StoryAnalyzer() {
        this.groups = {};
      }

      StoryAnalyzer.prototype.analyze = function(stories) {
        console.log(JSON.stringify(stories));
        return $.ajax({
          url: './analyze/many',
          type: 'POST',
          data: {
            "stories": JSON.stringify(stories)
          },
          dataType: 'json'
        }).done(function(resp) {
          return _.each(resp, function(r, i) {
            var story;
            story = stories.at(i);
            _.extend(story.attributes, _.omit(r, "title"));
            if ((r.lat != null) && (r.lng != null)) {
              story.trigger("find", story, story.get("lat"), story.get("lng"));
            }
            return story.trigger("done:analysis", story);
          });
        }).fail(function() {
          return console.log("error", arguments);
        }).always(function() {
          return console.log("complete", arguments);
        });
      };

      return StoryAnalyzer;

    })();
    Stories = (function(_super) {
      __extends(Stories, _super);

      function Stories() {
        return Stories.__super__.constructor.apply(this, arguments);
      }

      Stories.prototype.model = Story;

      Stories.prototype.url = "./stories/many";

      Stories.prototype.analysisLen = 4;

      Stories.prototype.initialize = function() {
        return this.analyzer = new StoryAnalyzer();
      };

      Stories.prototype.analyzeGroup = function(group, startIndex, endIndex) {
        if (group == null) {
          group = this;
        }
        if (startIndex == null) {
          startIndex = 0;
        }
        if (endIndex == null) {
          endIndex = this.analysisLen;
        }
        group = group.slice(startIndex, endIndex);
        if (group.length === 0) {
          return;
        }
        setTimeout((function(_this) {
          return function() {
            return _this.analyzeGroup(_this, endIndex, endIndex + _this.analysisLen);
          };
        })(this), 1000);
        return this.analyzer.analyze(new Stories(group));
      };

      Stories.prototype.analyze = function(group, startIndex, endIndex) {
        if (group == null) {
          group = this;
        }
        if (startIndex == null) {
          startIndex = 0;
        }
        if (endIndex == null) {
          endIndex = this.analysisLen;
        }
        return this.analyzeGroup();
      };

      Stories.prototype.getGroup = function(group) {
        if (!this.analyzer.groups[group]) {
          this.analyzer.groups[group] = new Stories();
        }
        return this.analyzer.groups[group];
      };

      Stories.prototype.addToGroup = function(group, id) {
        if (!this.analyzer.groups[group]) {
          this.analyzer.groups[group] = new Stories();
        }
        return this.analyzer.groups[group].add(this._byId[id]);
      };

      Stories.prototype.create = function() {
        this.each((function(_this) {
          return function(story) {
            return story.set("query_id", _this.query.id || _this.query.get("id"));
          };
        })(this));
        return Backbone.sync("create", this, {
          success: function() {},
          error: function() {}
        });
      };

      return Stories;

    })(Backbone.Collection);
    QuickStory = (function(_super) {
      __extends(QuickStory, _super);

      function QuickStory() {
        return QuickStory.__super__.constructor.apply(this, arguments);
      }

      QuickStory.prototype.template = _.template($("#quick-story-popup").html() || "");

      QuickStory.prototype.className = 'quick-story';

      QuickStory.prototype.tagName = 'dl';

      QuickStory.prototype.render = function() {
        this.$el.html(this.template(this.model.toJSON()));
        return this;
      };

      QuickStory.prototype.events = {
        click: function() {
          return this.model.trigger("center");
        }
      };

      return QuickStory;

    })(Backbone.View);
    StoryItem = (function(_super) {
      __extends(StoryItem, _super);

      function StoryItem() {
        return StoryItem.__super__.constructor.apply(this, arguments);
      }

      StoryItem.prototype.template = "#story-item";

      StoryItem.prototype.tagName = 'li';

      StoryItem.prototype.initialize = function() {
        this.popup = new QuickStory({
          model: this.model
        });
        _.bindAll(this, "scrollToThis");
        return this.listenTo(this.model, {
          "find": (function(_this) {
            return function(story) {
              return _this.$el.addClass("has-coordinates");
            };
          })(this),
          "highlight": function() {
            return this.$el.addClass("highlighted");
          },
          "unhighlight": function() {
            return this.$el.removeClass("highlighted");
          },
          "hide": function() {
            return this.$el.hide();
          },
          "show": function() {
            return this.$el.show();
          },
          "showpopup": this.togglePopup,
          "change:content": function() {
            alert("changed ");
            return console.log(arguments);
          }
        });
      };

      StoryItem.prototype.launchLocationPicker = function() {
        var modal;
        modal = new Modal({
          content: new GeoCoderView({
            model: this.model
          }).render().el
        });
        return modal.launch();
      };

      StoryItem.prototype.onRender = function() {
        if (this.model.hasCoordinates()) {
          return this.$el.addClass("has-coordinates");
        }
      };

      StoryItem.prototype.getPosition = function() {
        return this.$el.position().top;
      };

      StoryItem.prototype.togglePopup = function() {
        this.popup.render();
        $(".quick-story").not(this.popup.el).slideUp("fast");
        if (this.$(".quick-story").length === 0) {
          this.popup.$el.hide().appendTo(this.$el);
        }
        return this.popup.$el.slideToggle("fast", this.scrollToThis);
      };

      StoryItem.prototype.scrollToThis = function() {
        var $parent, pos;
        $parent = $("ul.story-list-wrapper");
        pos = this.getPosition() + $parent.scrollTop() - 100;
        return $parent.animate({
          scrollTop: pos
        }, 300);
      };

      StoryItem.prototype.events = {
        "click": function() {
          return this.togglePopup();
        },
        "click .js-set-location": function(e) {
          this.launchLocationPicker();
          return e.stopPropagation();
        },
        "mouseover": function() {
          return this.model.trigger("highlight");
        },
        "mouseout": function() {
          return this.model.trigger("unhighlight");
        },
        "dblclick .article-title": function() {
          var w;
          w = window.open(this.model.get("url"), "_blank");
          return w.focus();
        }
      };

      return StoryItem;

    })(Marionette.ItemView);
    StoryList = (function(_super) {
      __extends(StoryList, _super);

      function StoryList() {
        return StoryList.__super__.constructor.apply(this, arguments);
      }

      StoryList.prototype.el = '.all-stories ul.story-list-wrapper';

      StoryList.prototype.childView = StoryItem;

      StoryList.prototype.onBeforeRender = function() {
        return this.$el.empty();
      };

      StoryList.prototype.onRender = function() {
        return this.$(".placeholder").remove();
      };

      StoryList.prototype.setCollection = function(collection) {
        if (this.collection != null) {
          this.stopListening(this.collection);
        }
        this.collection = collection;
        return this.bindCollectionListeners();
      };

      StoryList.prototype.bindCollectionListeners = function() {
        return this.listenTo(this.collection, {
          "add": (function(_this) {
            return function(story) {
              var view;
              view = new _this.childView({
                model: story
              });
              return _this.$el.append(view.render().el);
            };
          })(this)
        });
      };

      return StoryList;

    })(Marionette.CollectionView);
    _activeStories = new Stories;
    _activeStoryList = new StoryList({
      collection: _activeStories
    });
    _activeStoryList.render();
    dispatcher.dispatch("set:activeStories", _activeStories);
    return {
      setActiveStories: function(stories) {
        if (stories instanceof Stories) {
          _activeStories = stories;
        } else {
          _activeStories = new Stories(stories, {
            parse: true
          });
        }
        dispatcher.dispatch("set:activeStories", _activeStories);
        _activeStoryList.setCollection(_activeStories);
        _activeStoryList.render();
        return _activeStories;
      },
      addToActiveSet: function(stories) {
        var story;
        if (_.isArray(stories)) {
          return _.each(stories, function(story) {
            story = new Story(story, {
              parse: true
            });
            _activeStories.add(story);
            _activeStories._byId[story.get("title")] = story;
            return _activeStories.addToGroup(story.get("aggregator"), story.get("title"));
          });
        } else {
          story = new Story(stories, {
            parse: true
          });
          _activeStories.add(story);
          _activeStories._byId[story.get("title")] = story;
          return _activeStories.addToGroup(stories.get("aggregator"), stories.get("title"));
        }
      },
      getActiveSet: function() {
        return _activeStories;
      },
      analyze: function(name, notify) {
        return _activeStories.analyze(name, notify);
      },
      Stories: Stories,
      StoryFilter: StoryFilter
    };
  });

}).call(this);
