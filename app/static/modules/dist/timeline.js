
/* OLD CODE, needs to be refactored a LOT */

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define("timeline", ["hub", "user", "map"], function(hub, user, map) {
    var DateRange, Timeline, TimelineMarker, TwoDatePicker, dispatcher;
    DateRange = (function(_super) {
      __extends(DateRange, _super);

      function DateRange() {
        return DateRange.__super__.constructor.apply(this, arguments);
      }

      DateRange.prototype.defaults = function() {
        return {
          absoluteMinimum: 0,
          absoluteMaximum: Date.now(),
          currentMinimum: 0,
          currentMaximum: Date.now()
        };
      };

      DateRange.prototype.init = function() {
        return this.dates = [];
      };

      DateRange.prototype.getStartDate = function() {
        return this.dates[0];
      };

      DateRange.prototype.getEndDate = function() {
        return this.dates[1];
      };

      DateRange.prototype.setEndDate = function(end) {
        end = new Date(end);
        return this.dates[1] = end.getTime();
      };

      DateRange.prototype.setStartDate = function(start) {
        start = new Date(start);
        return this.dates[0] = start.getTime();
      };

      DateRange.prototype.setAbsoluteUpperBound = function(bound) {
        this.$startElement.datepicker("option", "maxDate", new Date(bound));
        this.$endElement.datepicker("option", "maxDate", new Date(bound));
        return this.absoluteUpperBound = bound;
      };

      DateRange.prototype.setAbsoluteLowerBound = function(bound) {
        this.$startElement.datepicker("option", "minDate", new Date(bound));
        this.$endElement.datepicker("option", "minDate", new Date(bound));
        return this.absoluteLowerBound = bound;
      };

      return DateRange;

    })(Backbone.Model);
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
        var format, _ref;
        format = (_ref = user.getActiveUser()) != null ? _ref.get("preferences").get("date_format") : void 0;
        _.bindAll(this, "render", "addMarker", "changeValue", "play", "stop", "updateHandles");
        this.previousCutoff = 0;
        this.updateVisibleMarkers = (function(_this) {
          return function(e, ui) {
            var activeMap, cleaned, display, handle, pos, range;
            handle = $(ui.handle);
            pos = handle.index() - 1;
            range = ui.values;
            cleaned = moment(range[pos]).format(format);
            display = $("<div/>").addClass("handle-display-value").text(cleaned);
            handle.find("div").remove().end().append(display);
            activeMap = map.getActiveMap();
            _this.previousCutoff = activeMap.filterByDate(ui.values[0], ui.values[1], _this.previousCutoff, {
              hideTimelineMarkers: false
            });
            return console.log(_this.previousCutoff);
          };
        })(this);
        this.$timeline = this.$(".slider");
        this.$timeline.slider({
          range: true,
          values: [0, 100],
          step: 10000,
          slide: (function(_this) {
            return function() {
              return _this.updateVisibleMarkers.apply(_this, arguments);
            };
          })(this),
          change: (function(_this) {
            return function() {
              return _this.updateVisibleMarkers.apply(_this, arguments);
            };
          })(this)
        });
        return this.listenTo(dispatcher, "render:timeline", (function(_this) {
          return function() {
            _this.render().updateHandles();
            return _this.show();
          };
        })(this));
      };

      Timeline.prototype.hide = function() {
        this.$el.css("bottom", -400);
        return this;
      };

      Timeline.prototype.show = function() {
        this.$el.css("bottom", 0);
        return this;
      };

      Timeline.prototype.reset = function() {
        this.previousCutoff = 0;
        this.min = this.max = void 0;
        return this;
      };

      Timeline.prototype.clearMarkers = function() {
        this.$(".timeline-marker").remove();
        return this;
      };

      Timeline.prototype.render = function() {
        this.previousCutoff = 0;
        this.clearMarkers();
        _.each(this.collection.models, (function(_this) {
          return function(story) {
            return _this.addMarker(story);
          };
        })(this));
        this.updateDatePicker();
        return this;
      };

      Timeline.prototype.updateDatePicker = function() {
        var absMax, absMin, range, _ref;
        if ((_ref = this.twoDatePicker) != null) {
          _ref.destroy();
        }
        this.date;
        this.twoDatePicker = new TwoDatePicker(document.getElementById("start-date-picker"), document.getElementById("end-date-picker"));
        range = this.twoDatePicker;
        range.setAbsoluteLowerBound(absMin = this.min);
        range.setAbsoluteUpperBound(absMax = this.max);
        return range.setTimelineInterface({
          render: (function(_this) {
            return function() {
              return _this.updateHandles();
            };
          })(this),
          updateLowerBound: (function(_this) {
            return function(bound) {
              console.log(bound, _this);
              return _this.min = bound;
            };
          })(this),
          updateUpperBound: (function(_this) {
            return function(bound) {
              return _this.max = bound;
            };
          })(this)
        });
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
        this.previousCutoff = 0;
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

      Timeline.prototype.destroy = function() {
        this.undelegateEvents();
        return this.$el.removeData().unbind();
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
        if (!this.model.hasCoordinates()) {
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
    TwoDatePicker = (function() {
      function TwoDatePicker(startElement, endElement, dateRange) {
        this.startElement = startElement;
        this.endElement = endElement;
        this.dateRange = dateRange;
        this.$startElement = $(this.startElement);
        this.$endElement = $(this.endElement);
        this.bindDatePicker(this.$startElement, "start");
        this.bindDatePicker(this.$endElement, "end");
        _.extend(this, Backbone.Events);
        this.bindRangeListeners();
      }

      TwoDatePicker.prototype.bindRangeListeners = function() {
        return this.listenTo(this.dateRange, {
          "change:currentMinimum": this.updateCurrentMinimum,
          "change:currentMaximum": this.updateCurrentMaximum
        });
      };

      TwoDatePicker.prototype.updateCurrentMaximum = function(model, max) {
        return this.$endElement.datepicker("setDate", max);
      };

      TwoDatePicker.prototype.updateCurrentMinimum = function(model, min) {
        return this.$startElement.datepicker("setDate", min);
      };

      TwoDatePicker.prototype.bindDatePicker = function(el, which) {
        return el.datepicker({
          maxDate: this.absoluteUpperBound,
          minDate: this.absoluteLowerBound,
          showAnim: "fadeIn",
          onSelect: (function(_this) {
            return function(date, evt) {
              if (which === "start") {
                _this.timelineInterface.updateLowerBound(new Date(date));
                _this.timelineInterface.render();
                return false;
              }
            };
          })(this)
        });
      };

      TwoDatePicker.prototype.destroy = function() {
        return this.stopListening();
      };

      TwoDatePicker.prototype.setTimelineInterface = function(timelineInterface) {
        this.timelineInterface = timelineInterface;
      };

      return TwoDatePicker;

    })();
    return {
      TimelineView: Timeline,
      TwoDatePicker: TwoDatePicker,
      DateRange: DateRange
    };
  });

}).call(this);
