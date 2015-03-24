(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(["hub", "themes", "stories"], function(hub, themes, stories) {
    var Map, MapFactory, MapMarker, blueIcon, dispatcher, map, redIcon;
    dispatcher = hub.dispatcher;
    blueIcon = "static/images/bluepoi.png";
    redIcon = "static/images/redpoi.png";
    MapMarker = (function(_super) {
      __extends(MapMarker, _super);

      function MapMarker() {
        return MapMarker.__super__.constructor.apply(this, arguments);
      }

      MapMarker.prototype.tagName = 'div';

      MapMarker.prototype.template = _.template($("#storymarker").html());

      MapMarker.prototype.initialize = function(attrs) {
        this.map = attrs.map;
        _.bindAll(this, "render");
        return this.listenTo(this.model, {
          "hide": function() {
            console.log("hiding");
            if ((this.icon != null) && (this.icon.getMap() != null)) {
              return this.icon.setMap(null);
            }
          },
          "show": function() {
            if ((this.icon != null) && (this.icon.getMap() == null)) {
              return this.icon.setMap(this.map);
            }
          },
          "highlight": function(bounce) {
            if (bounce == null) {
              bounce = true;
            }
            if (this.icon != null) {
              this.icon.setIcon(blueIcon);
              this.icon.setZIndex(100);
              if (bounce === true) {
                return this.bounceMarker();
              }
            }
          },
          "unhighlight": function(stopBouncing) {
            if (stopBouncing == null) {
              stopBouncing = true;
            }
            if (this.icon != null) {
              this.icon.setIcon(redIcon);
              this.icon.setZIndex(1);
              if (stopBouncing === true) {
                return this.stopBouncingMarker();
              }
            }
          },
          "showpopup": function() {
            if ((this.icon != null) && this.map.getZoom() >= 7) {
              return this.map.setCenter(this.icon.getPosition());
            }
          },
          "center": function() {
            if (this.icon != null) {
              return this.map.setCenter(this.icon.getPosition());
            }
          }
        });
      };

      MapMarker.prototype.bounceMarker = function() {
        this.mouseentertime = new Date().getTime();
        this.icon.setAnimation(google.maps.Animation.BOUNCE);
        if (this.mouseleavetimeout) {
          return clearTimeout(this.mouseleavetimeout);
        }
      };

      MapMarker.prototype.stopBouncingMarker = function() {
        var bounce_diff, now;
        now = new Date().getTime();
        bounce_diff = (now - this.mouseentertime) % 700;
        this.icon.setZIndex(1);
        return this.mouseleavetimeout = setTimeout((function(_this) {
          return function() {
            return _this.icon.setAnimation(null);
          };
        })(this), 700 - bounce_diff);
      };

      MapMarker.prototype.render = function() {
        var pt, xOff, yOff;
        this.$el.html(this.template(this.model.toJSON()));
        this.xoff = xOff = Math.random() * 0.1;
        this.yoff = yOff = Math.random() * 0.1;
        pt = new google.maps.LatLng(parseFloat(this.model.get("lat")) + xOff, parseFloat(this.model.get("lng")) + yOff);
        this.icon = new google.maps.Marker({
          position: pt,
          animation: google.maps.Animation.DROP,
          title: this.model.get("title"),
          icon: redIcon,
          map: this.map,
          ZIndex: 1
        });
        return this;
      };

      return MapMarker;

    })(Backbone.View);
    Map = (function(_super) {
      __extends(Map, _super);

      function Map() {
        return Map.__super__.constructor.apply(this, arguments);
      }

      Map.prototype.tagName = "div";

      Map.prototype.className = "map-canvas";

      Map.prototype.filterByDate = function(min, max, opts) {
        var inrange, outrange;
        if (opts == null) {
          opts = {};
        }
        inrange = [];
        outrange = [];
        if (this.collection != null) {
          return this.collection.each(function(model) {
            var date;
            date = model.get("date");
            if (date >= min && date <= max) {
              return model.trigger("show", opts);
            } else {
              return model.trigger("hide", opts);
            }
          });
        }
      };

      Map.prototype.initialize = function(attrs) {
        this.id = attrs.id;
        this.markers = [];
        return this.mapOptions = {
          center: new google.maps.LatLng(35, -62),
          zoom: 2,
          minZoom: 2,
          mapTypeControl: false,
          mapTypeId: google.maps.MapTypeId.ROADMAP,
          zoomControlOptions: {
            position: google.maps.ControlPosition.LEFT_CENTER
          },
          panControlOptions: {
            position: google.maps.ControlPosition.LEFT_CENTER
          }
        };
      };

      Map.prototype.render = function() {
        this.$el.attr("id", this.id).appendTo(hub.getRegion("mapWrapper").$el);
        this.map = new google.maps.Map(this.el, this.mapOptions);
        return this;
      };

      Map.prototype.setCollection = function(collection) {
        if (this.collection) {
          this.stopListening(this.collection);
        }
        this.collection = collection;
        return this.bindCollectionListeners();
      };

      Map.prototype.bindCollectionListeners = function() {
        return this.listenTo(this.collection, {
          "find": (function(_this) {
            return function(story) {
              return _this.plot(story);
            };
          })(this)
        });
      };

      Map.prototype.plot = function(story) {
        var j, markerIcon;
        j = story.toJSON();
        if (!((j.lat == null) || (j.lng == null) || _.isUndefined(j.lat) || _.isUndefined(j.lng))) {
          story.marker = new MapMarker({
            model: story,
            map: this.map
          }).render();
          markerIcon = story.marker.icon;
          this.bindEventsOnMarker(story.marker);
          markerIcon.setMap(this.map);
          this.markers.push(markerIcon);
          story.set("hasLocation", true);
        } else {
          story.set("hasLocation", false);
        }
        story.trigger("doneloading");
        return this;
      };

      Map.prototype.clear = function() {
        _.each(this.markers, function(marker) {
          return marker.setMap(null);
        });
        return this;
      };

      Map.prototype.plotAll = function() {
        if (this.collection != null) {
          return this.collection.each((function(_this) {
            return function(story) {
              return _this.plot(story);
            };
          })(this));
        }
      };

      Map.prototype.bindEventsOnMarker = function(markerObj) {
        var display;
        display = markerObj.$el.html();
        google.maps.event.addListener(markerObj.icon, "click", (function(_this) {
          return function() {
            console.log(markerObj.model.toJSON());
            return markerObj.model.trigger("showpopup");
          };
        })(this));
        google.maps.event.addListener(markerObj.icon, "mouseover", (function(_this) {
          return function() {
            return markerObj.model.trigger("highlight", false);
          };
        })(this));
        google.maps.event.addListener(markerObj.icon, "mouseout", (function(_this) {
          return function() {
            return markerObj.model.trigger("unhighlight", false);
          };
        })(this));
        return this;
      };

      return Map;

    })(Backbone.View);
    MapFactory = (function() {
      var currentId;
      currentId = 0;
      return function() {
        return new Map("canvas-" + ++currentId);
      };
    })();
    map = null;
    dispatcher.on("add:map", function() {
      if (map === null) {
        return map = MapFactory().render();
      }
    });
    dispatcher.on("clear:map", function() {
      return map.clear();
    });
    dispatcher.on("plot:story", function() {
      return map.plot.apply(map, arguments);
    });
    dispatcher.on("plotAll:stories", function() {
      return map.plotAll.apply(map, arguments);
    });
    dispatcher.on("set:activeStories", function(stories) {
      map.setCollection(stories);
      return map.plotAll();
    });
    dispatcher.on("filter:markers", function(min, max, opts) {
      if (opts == null) {
        opts = {};
      }
      _.extend({
        hideTimelineMarkers: true,
        hideMapMarker: true
      }, opts);
      return map.filterByDate(min, max, opts);
    });
    return {
      getActiveMap: function() {
        return map;
      },
      Factory: MapFactory
    };
  });

}).call(this);
