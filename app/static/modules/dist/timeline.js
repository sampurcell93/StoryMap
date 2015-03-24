
/* OLD CODE, needs to be refactored a LOT */

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(["hub", "user"], function(hub, user) {
    var Timeline, TimelineMarker, dispatcher;
    dispatcher = hub.dispatcher;
    Timeline = (function(_super) {
      __extends(Timeline, _super);

      function Timeline() {
        return Timeline.__super__.constructor.apply(this, arguments);
      }

      Timeline.prototype.el = 'footer';

      Timeline.prototype.speeds = {
        forward: 32,
        back: 32
      };

      Timeline.prototype.dir = "forward";

      Timeline.prototype.initialize = function() {
        var format, update_val, _ref;
        format = (_ref = user.getActiveUser()) != null ? _ref.get("preferences").get("date_format") : void 0;
        _.bindAll(this, "render", "addMarker", "changeValue", "play", "stop", "updateHandles");
        update_val = (function(_this) {
          return function(e, ui) {
            var cleaned, display, handle, pos, range;
            handle = $(ui.handle);
            pos = handle.index() - 1;
            range = ui.values;
            cleaned = moment(range[pos]).format(format);
            display = $("<div/>").addClass("handle-display-value").text(cleaned);
            handle.find("div").remove().end().append(display);
            return dispatcher.dispatch("filter:markers", ui.values[0], ui.values[1], {
              hideTimelineMarkers: false
            });
          };
        })(this);
        this.$timeline = this.$(".slider");
        this.$timeline.slider({
          range: true,
          values: [0, 100],
          step: 10000,
          slide: update_val,
          change: update_val
        });
        return this;
      };

      Timeline.prototype.reset = function() {
        this.min = this.max = void 0;
        return this;
      };

      Timeline.prototype.clearMarkers = function() {
        this.$(".timeline-marker").remove();
        return this;
      };

      Timeline.prototype.render = function() {
        this.clearMarkers();
        _.each(this.collection.models, (function(_this) {
          return function(story) {
            return _this.addMarker(story);
          };
        })(this));
        return this;
      };

      Timeline.prototype.addMarker = function(model) {
        var $slider, pixeladdition, pos, range, view, width;
        console.log("appending a MARKR ONTO TIMELINE");
        $slider = this.$(".slider-wrapper");
        width = $slider.width();
        pos = model.get("date").unix() * 1000;
        range = this.max - this.min;
        pos -= this.min;
        pos /= range;
        pixeladdition = 10 / width;
        view = new TimelineMarker({
          model: model,
          left: pos
        });
        $slider.append(view.render().el);
        return this;
      };

      Timeline.prototype.play = function() {
        var dir, hi, inc, lo, values;
        values = this.$timeline.slider("values");
        lo = values[0];
        hi = values[1];
        this.isPlaying = true;
        dir = this.dir === "forward" ? 1 : 1;
        inc = dir * Math.ceil(Math.abs((hi - lo) / 300));
        this.changeValue(lo, hi, inc, function(locmp, hicmp) {
          return locmp <= hicmp;
        });
        return this;
      };

      Timeline.prototype.stop = function() {
        this.isPlaying = false;
        this.$(".js-pause-timeline").trigger("switch");
        return this;
      };

      Timeline.prototype.toEnd = function() {
        var $tl, end;
        $tl = this.$timeline;
        this.stop();
        end = $tl.slider("option", "max");
        $tl.slider("values", 1, end);
        return end;
      };

      Timeline.prototype.toStart = function() {
        var $tl, start;
        $tl = this.$timeline;
        this.stop();
        start = $tl.slider("values", 0);
        $tl.slider("values", 1, start);
        return start;
      };

      Timeline.prototype.changeValue = function(lo, hi, increment, comparator) {
        window.setTimeout((function(_this) {
          return function() {
            var newlo;
            if (comparator(lo, hi) === true && _this.isPlaying === true) {
              newlo = lo + increment;
              _this.$timeline.slider("values", 1, newlo);
              return _this.changeValue(newlo, hi, increment, comparator);
            } else {
              return _this.stop();
            }
          };
        })(this), this.speeds[this.dir]);
        return this;
      };

      Timeline.prototype.updateHandles = function() {
        var $timeline, format, handles, max, maxdate, min, mindate, prevcomparator, _ref;
        if (this.collection.length < 2) {
          return this;
        }
        prevcomparator = this.collection.comparator;
        this.collection.comparator = function(model) {
          return model.get("date");
        };
        format = (_ref = user.getActiveUser()) != null ? _ref.get("preferences").get("date_format") : void 0;
        this.collection.sort();
        this.min = min = this.collection.first().get("date");
        this.max = max = this.collection.last().get("date");
        if (max.toDate == null) {
          this.max = max = moment(max);
        }
        if (min.toDate == null) {
          this.min = min = moment(min);
        }
        mindate = parseInt(min.unix() * 1000);
        maxdate = parseInt(max.unix() * 1000);
        $timeline = this.$timeline;
        handles = $timeline.find(".ui-slider-handle");
        handles.first().data("display-date", min.format(format));
        handles.last().data("display-date", max.format(format));
        $timeline.slider("option", {
          min: mindate,
          max: maxdate
        });
        $timeline.slider("values", 0, mindate);
        $timeline.slider("values", 1, maxdate);
        this.max = this.max.unix() * 1000;
        this.min = this.min.unix() * 1000;
        return this;
      };

      Timeline.prototype.setSpeed = function(dir) {
        var rel, speed;
        rel = Math.pow(2, 5);
        speed = this.speeds[dir];
        if (speed > 1) {
          speed /= 2;
        } else {
          speed = 32;
        }
        this.speeds[dir] = speed;
        this.dir = dir;
        return rel / speed;
      };

      Timeline.prototype.renderSpeed = function(e) {
        var $t, speed;
        if (e != null) {
          $t = $(e.currentTarget);
          speed = this.setSpeed($t.attr("dir" || "forward"));
          $t.attr("speed", speed + "x");
          return $t.addClass("selected").siblings(".js-speed-control").removeClass("selected");
        }
      };

      Timeline.prototype.zoomTo = function(date) {
        var $t, center, high, low, offset, offsetH, offsetL;
        if (!this.min || !this.max) {
          return this;
        }
        center = moment(date).unix() * 1000;
        offsetL = (this.max - center) / 2;
        offsetH = (center - this.min) / 2;
        offset = offsetL > offsetH ? offsetH : offsetL;
        $t = this.$timeline;
        low = parseInt(center - offset);
        high = parseInt(center + offset);
        $t.slider("values", 0, low);
        $t.slider("values", 1, high);
        return this;
      };

      Timeline.prototype.events = {
        "click .js-play-timeline": function(e) {
          $(e.currentTarget).removeClass("js-play-timeline icon-play2").addClass("js-pause-timeline icon-pause2 playing");
          if (!this.isPlaying) {
            return this.play();
          }
        },
        "click .js-pause-timeline": function(e) {
          $(e.currentTarget).removeClass("js-pause-timeline icon-pause2 playing").addClass("js-play-timeline icon-play2");
          return this.stop();
        },
        "switch .js-pause-timeline": function(e) {
          return $(e.currentTarget).removeClass("js-pause-timeline icon-pause2 playing").addClass("js-play-timeline icon-play2");
        },
        "click .js-fast-forward": "renderSpeed",
        "click .js-rewind": "renderSpeed",
        "click .js-to-end": "toEnd",
        "click .js-to-start": "toStart",
        "mouseover .timeline-controls li": function(e) {
          var $t;
          return $t = $(e.currentTarget);
        }
      };

      Timeline.prototype.destroy = function() {
        this.undelegateEvents();
        return this.$el.removeData().unbind();
      };

      return Timeline;

    })(Backbone.View);
    TimelineMarker = (function(_super) {
      __extends(TimelineMarker, _super);

      function TimelineMarker() {
        return TimelineMarker.__super__.constructor.apply(this, arguments);
      }

      TimelineMarker.prototype.className = 'timeline-marker';

      TimelineMarker.prototype.template = _.template($("#date-bubble").html());

      TimelineMarker.prototype.initialize = function(attrs) {
        this.left = attrs.left;
        return this.listenTo(this.model, {
          "hide": function(opts) {
            if (opts == null) {
              opts = {};
            }
            if (opts.hideTimelineMarkers !== false) {
              return this.$el.hide();
            }
          },
          "show": function(opts) {
            if (opts == null) {
              opts = {};
            }
            return this.$el.show();
          },
          "highlight": function() {
            return this.$el.addClass("highlighted");
          },
          "unhighlight": function() {
            return this.$el.removeClass("highlighted");
          },
          "change:hasLocation": function(model, hasLocation) {
            if (hasLocation) {
              return this.$el.removeClass("no-location-marker");
            } else {
              return this.$el.addClass("no-location-marker");
            }
          }
        });
      };

      TimelineMarker.prototype.render = function() {
        var $el, format, num, _ref;
        format = (_ref = user.getActiveUser()) != null ? _ref.get("preferences").get("date_format") : void 0;
        num = this.left;
        $el = this.$el;
        $el.css('left', (num * 100) + "%");
        $el.html(this.template({
          date: this.model.get("date").format(format)
        }));
        if (!this.model.hasLocation()) {
          $el.addClass("no-location-marker");
        }
        this.$(".date-bubble").hide();
        return this;
      };

      TimelineMarker.prototype.events = {
        "mouseover": function() {
          return this.model.trigger("highlight");
        },
        "mouseout": function() {
          return this.model.trigger("unhighlight");
        },
        "click": function(e) {
          return this.model.trigger("showpopup");
        }
      };

      return TimelineMarker;

    })(Backbone.View);
    return {
      TimelineView: Timeline
    };
  });

}).call(this);
