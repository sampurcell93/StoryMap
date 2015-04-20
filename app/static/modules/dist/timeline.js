
/* OLD CODE, needs to be refactored a LOT */

(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define("timeline", ["hub", "user", "map", "BST"], function(hub, user, map, BST) {
    var DateRange, TimelineFactory, TimelineMarker, TimelineView, TwoDatePicker, TwoDatePickerFactory, dispatcher, _format, _ref;
    _format = (_ref = user.getActiveUser()) != null ? _ref.get("preferences").get("date_format") : void 0;
    console.log(_format);
    DateRange = (function(_super) {
      __extends(DateRange, _super);

      function DateRange() {
        return DateRange.__super__.constructor.apply(this, arguments);
      }

      DateRange.prototype.defaults = function() {
        var epoch, now;
        now = moment().valueOf();
        epoch = moment(0).valueOf();
        return {
          absoluteMinimum: epoch,
          absoluteMaximum: now,
          activeUpperValue: now,
          activeLowerValue: epoch,
          currentMinimum: epoch,
          currentMaximum: now
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
        return this.set("absoluteMaximum", bound);
      };

      DateRange.prototype.setAbsoluteLowerBound = function(bound) {
        return this.set("absoluteMinimum", bound);
      };

      DateRange.prototype.setCollection = function(collection) {
        var max, min;
        if (collection == null) {
          throw Error("Invalid or null collection passed to Date Range.");
        }
        if (_.isEqual(collection, this.collection)) {
          return this;
        }
        this.collection = collection;
        min = max = collection.first().get("date").valueOf();
        collection.each((function(_this) {
          return function(model) {
            var date;
            date = model.get("date").valueOf();
            if (date > max) {
              max = date;
            }
            if (date < min) {
              return min = date;
            }
          };
        })(this));
        return this.set({
          "absoluteMinimum": min,
          "absoluteMaximum": max,
          "activeLowerValue": min,
          "activeUpperValue": max,
          "currentMinimum": min,
          "currentMaximum": max
        });
      };

      return DateRange;

    })(Backbone.Model);
    dispatcher = hub.dispatcher;
    TimelineView = (function(_super) {
      __extends(TimelineView, _super);

      function TimelineView() {
        return TimelineView.__super__.constructor.apply(this, arguments);
      }

      TimelineView.prototype.el = "footer";

      TimelineView.prototype.initialize = function(attrs) {
        this.format = _format;
        this.isPlaying = false;
        _.extend(this, attrs);
        _.bindAll(this, "updateVisibleMarkers");
        if (this.collection != null) {
          this.setCollection(this.collection);
        }
        this.bindJqueryUIRangeSlider();
        this.listenToDateRange();
        return this;
      };

      TimelineView.prototype.listenToDateRange = function() {
        return this.listenTo(this.dateRange, {
          "change:absoluteMinimum change:currentMinimum change:activeLowerValue change:activeUpperValue change:absoluteMaximum change:currentMaximum": (function(_this) {
            return function(range, date, obj) {
              return _this.updateRenderedBounds();
            };
          })(this)
        });
      };

      TimelineView.prototype.bindJqueryUIRangeSlider = function() {
        var dataApplicator;
        this.$timeline = this.$(".slider");
        dataApplicator = (function(_this) {
          return function(e, ui) {
            var $handle, cleanedDate, pos, range;
            $handle = $(ui.handle);
            pos = $handle.index() - 1;
            range = ui.values;
            cleanedDate = moment(range[pos]).format(_this.format);
            _this.updateDateHandle($handle, cleanedDate);
            _this.dateRange.set("activeLowerValue", ui.values[0], {
              silent: true
            });
            _this.dateRange.set("activeUpperValue", ui.values[1], {
              silent: true
            });
            return _this.updateVisibleMarkers(ui.values[0], ui.values[1]);
          };
        })(this);
        return this.$timeline.slider({
          range: true,
          values: [this.dateRange.get("absoluteMinimum"), this.dateRange.get("absoluteMaximum")],
          step: 10000,
          slide: (function(_this) {
            return function(e, ui) {
              return dataApplicator.apply(_this, arguments);
            };
          })(this),
          change: (function(_this) {
            return function(e, ui) {
              return dataApplicator.apply(_this, arguments);
            };
          })(this)
        });
      };

      TimelineView.prototype.updateDateHandle = function(handle, date) {
        var display;
        display = $("<div/>").addClass("handle-display-value").text(date);
        return handle.find("div").remove().end().append(display);
      };

      TimelineView.prototype.updateVisibleMarkers = function(lowBound, highBound) {
        var inBounds, outBounds;
        inBounds = this.BST.betweenBounds({
          $gte: lowBound,
          $lte: highBound
        });
        outBounds = this.BST.betweenBounds({
          $lt: lowBound
        }).concat(this.BST.betweenBounds({
          $gt: highBound
        }));
        _.each(inBounds, (function(_this) {
          return function(inbound) {
            return inbound.trigger("show");
          };
        })(this));
        _.each(outBounds, (function(_this) {
          return function(outbound) {
            return outbound.trigger("hide");
          };
        })(this));
        return this.prevHighBound = highBound;
      };

      TimelineView.prototype.setRange = function(range) {
        if (range == null) {
          throw Error("Invalid range supplied to Timeline View.");
        }
        this.dateRange = range;
        return this;
      };

      TimelineView.prototype.getRange = function() {
        return this.dateRange;
      };

      TimelineView.prototype.setCollection = function(collection) {
        if (collection == null) {
          throw Error("Invalid or null collection passed to Timeline View.");
        }
        if (_.isEqual(collection, this.collection)) {
          return this;
        }
        this.collection = collection;
        this._constructBST();
        this.updateRenderedBounds();
        return this;
      };

      TimelineView.prototype.updateRenderedBounds = function() {
        var $timeline, activeMax, activeMin, currMax, currMin, handles;
        $timeline = this.$timeline;
        currMin = this.dateRange.get("currentMinimum");
        currMax = this.dateRange.get("currentMaximum");
        activeMin = this.dateRange.get("activeLowerValue");
        activeMax = this.dateRange.get("activeUpperValue");
        if (currMin < activeMin) {
          this.dateRange.set("activeLowerValue", currMin);
          activeMin = this.dateRange.get("activeLowerValue");
        }
        if (currMax < activeMax) {
          this.dateRange.set("activeUpperValue", currMax);
          activeMax = this.dateRange.get("activeUpperValue");
        }
        handles = $timeline.find(".ui-slider-handle");
        $timeline.slider("option", {
          min: currMin,
          max: currMax
        });
        $timeline.slider("values", 0, activeMin);
        $timeline.slider("values", 1, activeMax);
        return this;
      };

      TimelineView.prototype._constructBST = function() {
        this.BST = new BST.BST({
          compareKeys: function(a, b) {
            if (a < b) {
              return -1;
            }
            if (a > b) {
              return 1;
            }
            return 0;
          }
        });
        this.collection.each((function(_this) {
          return function(model) {
            var _ref1;
            return _this.BST.insert((_ref1 = model.get(_this.index)) != null ? _ref1.toDate() : void 0, model);
          };
        })(this));
        return this;
      };

      TimelineView.prototype.hide = function() {
        this.$el.css("bottom", -400);
        return this;
      };

      TimelineView.prototype.show = function() {
        return this.$el.fadeIn("fast").css("bottom", 0);
      };

      TimelineView.prototype.addMarker = function(model) {
        var $slider, pos, view;
        $slider = this.$(".slider-wrapper");
        pos = new Date(model.get(this.index)).getTime();
        pos = (pos(-this.min)) / (this.max - this.min);
        view = new TimelineMarker({
          model: model,
          left: pos
        });
        $slider.append(view.render().el);
        return this;
      };

      TimelineView.prototype.getPlayer = function() {
        var highBound, increment, lowBound, play;
        lowBound = this.dateRange.get("activeLowerValue");
        highBound = this.dateRange.get("currentMaximum");
        increment = Math.ceil(Math.abs((highBound - lowBound) / 300));
        play = (function(_this) {
          return function() {
            var newVal;
            newVal = _this.dateRange.get("activeUpperValue") + increment;
            _this.dateRange.set("activeUpperValue", newVal);
            if (newVal >= _this.dateRange.get("currentMaximum")) {
              _this.stop();
              return;
            }
            return _this.player = requestAnimationFrame(play);
          };
        })(this);
        return (function(_this) {
          return function() {
            console.log(new Date(lowBound));
            _this.dateRange.set("activeUpperValue", lowBound, {
              silent: true
            });
            return _this.player = requestAnimationFrame(play);
          };
        })(this);
      };

      TimelineView.prototype.toEnd = function() {
        this.stop();
        return this.$timeline.slider("values", 1, this.dateRange.get("absoluteMaximum"));
      };

      TimelineView.prototype.toStart = function() {
        this.stop();
        return this.$timeline.slider("values", 1, this.dateRange.get("absoluteMinimum"));
      };

      TimelineView.prototype.stop = function() {
        this.$(".js-pause-timeline").trigger("click");
        return this;
      };

      TimelineView.prototype.events = {
        "click .js-play-timeline": function(e) {
          var play;
          $(e.currentTarget).removeClass("js-play-timeline icon-play2").addClass("js-pause-timeline icon-pause2 playing");
          play = this.getPlayer();
          return play();
        },
        "click .js-pause-timeline": function(e) {
          $(e.currentTarget).removeClass("js-pause-timeline icon-pause2 playing").addClass("js-play-timeline icon-play2");
          return cancelAnimationFrame(this.player);
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

      return TimelineView;

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
        var $el, format, num, _ref1;
        format = (_ref1 = user.getActiveUser()) != null ? _ref1.get("preferences").get("date_format") : void 0;
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
      function TwoDatePicker(opts) {
        if (opts == null) {
          opts = {};
        }
        _.extend(this, opts);
        this.$startElement = $(this.startElement);
        this.$endElement = $(this.endElement);
        this.bindDatePicker(this.$startElement, "start");
        this.bindDatePicker(this.$endElement, "end");
        _.extend(this, Backbone.Events);
        this.bindRangeListeners();
        this.updateCurrentMinimum(null, this.dateRange.get("currentMinimum"));
        this.updateCurrentMaximum(null, this.dateRange.get("currentMaximum"));
      }

      TwoDatePicker.prototype.bindRangeListeners = function() {
        return this.listenTo(this.dateRange, {
          "change:currentMaximum": this.updateCurrentMaximum,
          "change:currentMinimum": this.updateCurrentMinimum
        });
      };

      TwoDatePicker.prototype.updateCurrentMaximum = function(model, max) {
        return this.$endElement.datepicker("setDate", new Date(max));
      };

      TwoDatePicker.prototype.updateCurrentMinimum = function(model, min) {
        return this.$startElement.datepicker("setDate", new Date(min));
      };

      TwoDatePicker.prototype.bindDatePicker = function(el, which) {
        return el.datepicker({
          maxDate: this.dateRange.get("absoluteMaximum"),
          minDate: this.dateRange.get("absoluteMinimum"),
          showAnim: "fadeIn",
          inline: true,
          showOtherMonths: true,
          hideIfNoPrevNext: true,
          numberOfMonths: [1, 2],
          dayNamesMin: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          onSelect: (function(_this) {
            return function(date, evt) {
              var currentMaximum, currentMinimum;
              date = moment(date).valueOf();
              currentMinimum = _this.dateRange.get("currentMinimum");
              currentMaximum = _this.dateRange.get("currentMaximum");
              el.blur();
              if (which === "start") {
                return _this.dateRange.set("currentMinimum", date);
              } else {
                return _this.dateRange.set("currentMaximum", date);
              }
            };
          })(this),
          onClose: function() {
            return el.blur();
          }
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
    TimelineFactory = function() {
      return function(opts) {
        if (opts == null) {
          opts = {};
        }
        opts = _.extend({
          index: "date",
          dateRange: new DateRange(),
          collection: new Backbone.Collection
        }, opts);
        return new TimelineView(opts);
      };
    };
    TwoDatePickerFactory = function() {
      return function(opts) {
        var picker, range;
        if (opts == null) {
          opts = {};
        }
        opts = _.extend({
          dateRange: new DateRange(),
          startElement: document.getElementById("start-date-picker"),
          endElement: document.getElementById("end-date-picker")
        }, opts);
        range = range || new DateRange();
        return picker = new TwoDatePicker(opts);
      };
    };
    return {
      TimelineFactory: TimelineFactory,
      TwoDatePickerFactory: TwoDatePickerFactory
    };
  });

}).call(this);
