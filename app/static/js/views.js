// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var blueIcon, redIcon;
    blueIcon = "/static/images/bluepoi.png";
    redIcon = "/static/images/redpoi.png";
    window.views = {};
    window.views.MapItem = Backbone.View.extend({
      el: 'section.map',
      url: function() {
        return '/favorite?user_id=' + this.model.user.id + "&query_id=" + this.currQuery.id;
      },
      initialize: function() {
        var self;
        console.log(this.model.user.id);
        _.bindAll(this, "render", "toggleMarkers", "search");
        self = this;
        this.model.instance = this;
        return this.listenTo(this.model, {
          "loading": this.createLoadingOverlay,
          "doneloading": function() {
            return window.destroyModal();
          }
        });
      },
      render: function() {
        var Underscore, self;
        self = this;
        Underscore = {
          compile: function(template) {
            var compiled;
            compiled = _.template(template);
            return {
              render: function(context) {
                return compiled(context);
              }
            };
          }
        };
        self.$(".js-news-search").typeahead([
          {
            name: 'Queries',
            template: $("#existing-query-item").html(),
            local: window.existingQueries.models,
            engine: Underscore,
            limit: 1000
          }
        ]);
        this.model.set("map", self.mapObj = new window.GoogleMap(this.model));
        this.articleList = new views.ArticleList({
          collection: this.model.get("articles"),
          map: this
        });
        this.timeline = new views.Timeline({
          collection: this.model.get("articles"),
          map: this
        });
        return this;
      },
      toggleMarkers: function(markers) {
        var self;
        self = this;
        _.each(markers.outrange, function(outlier) {
          return outlier.setMap(null);
        });
        _.each(markers.inrange, function(inlier) {
          if (inlier.getMap() == null) {
            return inlier.setMap(self.mapObj.map);
          }
        });
        return this;
      },
      search: function(query) {
        var map, self;
        self = this;
        map = this.model;
        map.trigger("loading");
        return map.getYahooNews(query).getGoogleNews(query, 0, function() {
          window.destroyModal();
          return _.each(map.get("articles").models, function(article) {
            console.log(article.toJSON());
            return article.getCalaisData();
          });
        });
      },
      events: {
        "keydown .js-news-search": function(e) {
          var key, val;
          key = e.keyCode || e.which;
          val = $(e.currentTarget).val();
          if (key === 13) {
            return this.model.checkExistingQuery(val, this.search);
          }
        },
        "click .go": function(e) {
          return this.search(this.$(".js-news-search").val());
        },
        "click [data-route]": function(e) {
          var $t, current_route, route;
          $t = $(e.currentTarget);
          route = $t.data("route");
          current_route = Backbone.history.fragment;
          return window.app.navigate(route, {
            trigger: true
          });
        },
        "click .js-save-query": function() {}
      },
      createLoadingOverlay: function() {
        var content;
        content = _.template($("#main-loading-message").html(), {});
        window.launchModal($("<div/>").append(content), {
          close: false
        });
        return this;
      }
    });
    window.views.MapMarker = Backbone.View.extend({
      tagName: 'div',
      template: $("#storymarker").html(),
      initialize: function() {
        this.map = this.options.map || window.map;
        return this.listenTo(this.model, {
          "hide": function() {
            if (this.marker != null) {
              return this.marker.setMap(null);
            }
          },
          "show": function() {
            if (this.marker != null) {
              return this.marker.setMap(this.map);
            }
          },
          "highlight": function() {
            if (this.marker != null) {
              return this.marker.setIcon(blueIcon);
            }
          },
          "unhighlight": function() {
            if (this.marker != null) {
              return this.marker.setIcon(redIcon);
            }
          }
        });
      },
      render: function() {
        var pt, xOff, yOff;
        this.$el.html(_.template(this.template, this.model.toJSON()));
        this.xoff = xOff = Math.random() * 0.1;
        this.yoff = yOff = Math.random() * 0.1;
        pt = new google.maps.LatLng(parseInt(this.model.get("latitude")) + xOff, parseInt(this.model.get("longitude")) + yOff);
        this.marker = new google.maps.Marker({
          position: pt,
          animation: google.maps.Animation.DROP,
          title: this.model.get("title"),
          icon: redIcon
        });
        return this;
      }
    });
    window.views.ArticleListItem = Backbone.View.extend({
      template: $("#article-item").html(),
      tagName: 'li',
      initialize: function() {
        var self;
        _.bindAll(this, "render");
        self = this;
        return this.listenTo(this.model, {
          "hide": function() {
            console.log("hiding");
            return this.$el.hide();
          },
          "show": function() {
            console.log("showing");
            return this.$el.show();
          },
          "loading": function() {
            cc("loading");
            return self.$el.prepend("<img class='loader' src='static/images/loader.gif' />");
          },
          "change:hasLocation": function() {
            return this.$el.addClass("has-location");
          }
        });
      },
      render: function() {
        this.$el.append(_.template(this.template, this.model.toJSON()));
        return this;
      },
      events: {
        "click": function() {
          return cc(this.model.toJSON());
        },
        "mouseover": function() {
          return this.model.trigger("highlight");
        },
        "mouseout": function() {
          return this.model.trigger("unhighlight");
        }
      }
    });
    window.views.ArticleList = Backbone.View.extend({
      el: '.all-articles',
      list: 'ol.article-list',
      sortopts: '.sort-options-list',
      hidden: false,
      events: {
        "click": function() {
          return cc(this.collection);
        }
      },
      initialize: function() {
        var self;
        self = this;
        this.map = this.options.map;
        _.bindAll(this, "render", "appendChild", "toggle", "filter");
        return this.listenTo(this.collection, "add", function(model) {
          return self.appendChild(model);
        });
      },
      appendChild: function(model) {
        var view;
        view = new views.ArticleListItem({
          model: model
        });
        this.$(this.list).find(".placeholder").remove().end().append(view.render().el);
        return this;
      },
      render: function() {
        var self;
        self = this;
        this.$(this.list).empty();
        _.each(this.collection.models, function(model) {
          return self.appendChild(model);
        });
        return this;
      },
      filter: function(query) {
        return _.each(this.collection.models, function(article) {
          var str;
          str = (article.toJSON().title + article.toJSON().content).toLowerCase();
          if (str.indexOf(query.toLowerCase()) === -1) {
            return article.trigger("hide");
          } else {
            return article.trigger("show");
          }
        });
      },
      toggle: function() {
        var map, smoothRender, startTime;
        this.hidden = !this.hidden;
        this.$el.toggleClass("away");
        map = this.map.mapObj.map;
        startTime = new Date().getTime();
        return smoothRender = setInterval(function() {
          var timeFromStart;
          timeFromStart = new Date().getTime() - startTime;
          google.maps.event.trigger(map, 'resize');
          map.setZoom(map.getZoom());
          if (timeFromStart >= 450) {
            return clearInterval(smoothRender);
          }
        }, 1);
      },
      events: {
        "keyup .js-filter-articles": function(e) {
          var $t, val;
          val = ($t = $(e.currentTarget)).val();
          return this.filter(val);
        },
        "click .js-toggle-view": "toggle",
        "click .placeholder": function() {
          return this.map.$(".js-news-search").focus();
        },
        'click .js-sort-options': function(e) {
          this.$(this.sortopts).toggle("fast");
          e.stopPropagation();
          return e.preventDefault();
        },
        'click .js-filter-param': function(e) {
          var $t, show;
          $t = $(e.currentTarget);
          show = $t.data("filtered");
          if (typeof show === "undefined") {
            show = true;
          }
          $t.data("filtered", !show);
          return cc($t.data("filtered"));
        },
        'click .js-sort-param': function(e) {
          var $siblings, $t;
          $t = $(e.currentTarget);
          return $siblings = $t.siblings(".js-sort-param");
        }
      }
    });
    window.views.Timeline = Backbone.View.extend({
      el: 'footer',
      speeds: {
        forward: 32,
        back: 32
      },
      dir: "forward",
      min: new Date,
      max: new Date(0),
      initialize: function() {
        var self, update_val;
        self = this;
        this.map = this.options.map;
        _.bindAll(this, "updateMinMax", "changeValue", "updateHandles", "play");
        this.listenTo(this.collection, "add", function(model) {
          self.updateMinMax(model);
          return self.updateHandles();
        });
        update_val = function(e, ui) {
          var cleaned, display, handle, pos, range;
          handle = $(ui.handle);
          pos = handle.index() - 1;
          range = ui.values;
          cleaned = new Date(range[pos]).cleanFormat();
          display = $("<div/>").addClass("handle-display-value").text(cleaned);
          handle.find("div").remove().end().append(display);
          return self.map.toggleMarkers(self.collection.filterByDate(ui.values[0], ui.values[1]));
        };
        this.$timeline = this.$(".timeline-slider");
        this.$timeline.slider({
          range: true,
          values: [0, 100],
          step: 10000,
          slide: update_val,
          change: update_val
        });
        return this;
      },
      render: function() {
        var self;
        self = this;
        _.each(this.collection.models, function(article) {
          if ((article.get("latitude") != null) && (article.get("longitude") != null)) {
            return self.addMarker(article);
          }
        });
        return this;
      },
      addMarker: function(model) {
        var pos, view;
        cc("appending a RED MARKR ONTO TIMELINE");
        pos = model.get("date").getTime();
        view = new views.TimelineMarker({
          model: model,
          left: pos / this.max
        });
        this.$(".slider-wrap").append(view.render().el);
        return this;
      },
      play: function() {
        var $timeline, dir, hi, inc, lo, values;
        $timeline = this.$timeline;
        values = $timeline.slider("values");
        lo = values[0];
        hi = values[1];
        this.isPlaying = true;
        dir = this.dir === "forward" ? 1 : -1;
        inc = dir * Math.ceil(Math.abs((hi - lo) / 300));
        cc(this.speeds[this.dir]);
        this.changeValue(lo, hi, inc, function(lo, hi) {
          return lo <= hi;
        });
        return this;
      },
      stop: function() {
        this.isPlaying = false;
        this.$(".js-pause-timeline").trigger("switch");
        return this;
      },
      changeValue: function(lo, hi, increment, comparator) {
        var self;
        self = this;
        window.setTimeout(function() {
          var newlo;
          if (comparator(lo, hi) === true && self.isPlaying === true) {
            newlo = lo + increment;
            self.$timeline.slider("values", 1, newlo);
            return self.changeValue(newlo, hi, increment, comparator);
          } else {
            return self.stop();
          }
        }, this.speeds[this.dir]);
        return this;
      },
      updateMinMax: function(model) {
        var date;
        if (model == null) {
          return this;
        }
        cc("updating min max");
        date = model.get("date");
        if (date < this.min) {
          this.min = date;
        }
        if (date > this.max) {
          this.max = date;
        }
        return this;
      },
      updateHandles: function() {
        var $timeline, handles, maxdate, mindate;
        cc("updating handles");
        $timeline = this.$timeline;
        handles = $timeline.find(".ui-slider-handle");
        handles.first().data("display-date", this.max.cleanFormat());
        handles.last().data("display-date", this.min.cleanFormat());
        mindate = this.min.getTime();
        maxdate = this.max.getTime();
        $timeline.slider("values", 0, mindate);
        $timeline.slider("values", 1, maxdate);
        $timeline.slider("option", {
          min: mindate,
          max: maxdate
        });
        return this;
      },
      setSpeed: function(dir) {
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
      },
      renderSpeed: function(e) {
        var $t, speed;
        if (e != null) {
          $t = $(e.currentTarget);
          speed = this.setSpeed($t.attr("dir" || "forward"));
          $t.attr("speed", speed + "x");
          return $t.addClass("selected").siblings(".js-speed-control").removeClass("selected");
        }
      },
      events: {
        "click .js-play-timeline": function(e) {
          $(e.currentTarget).removeClass("js-play-timeline").addClass("js-pause-timeline");
          if (!this.isPlaying) {
            return this.play();
          }
        },
        "click .js-pause-timeline": function(e) {
          $(e.currentTarget).removeClass("js-pause-timeline").addClass("js-play-timeline");
          return this.stop();
        },
        "switch .js-pause-timeline": function(e) {
          return $(e.currentTarget).removeClass("js-pause-timeline").addClass("js-play-timeline");
        },
        "click .js-fast-forward": "renderSpeed",
        "click .js-rewind": "renderSpeed",
        "mouseover .timeline-controls li": function(e) {
          var $t;
          return $t = $(e.currentTarget);
        }
      }
    });
    window.views.TimelineMarker = Backbone.View.extend({
      className: 'timeline-marker',
      render: function() {
        var num;
        num = this.options.left || (Math.random() * 100);
        console.log("putting marker at " + num);
        this.$el.css('left', (num * 100) + "%");
        return this;
      }
    });
    window.views.QueryThumb = Backbone.View.extend({
      tagName: 'li',
      template: $("#query-thumb").html(),
      searchComplete: function() {
        return console.log(arguments);
      },
      render: function() {
        this.$el.html(_.template(this.template, this.model.toJSON()));
        return this;
      }
    });
    return window.views.QueryThumbList = Backbone.View.extend({
      tagName: 'ul',
      className: 'query-thumb-list',
      appendChild: function(model) {
        var thumb;
        thumb = new views.QueryThumb({
          model: model
        });
        this.$el.append(thumb.render().el);
        return this;
      },
      render: function() {
        var self;
        self = this;
        this.$el.html("<h2>Your Saved Queries</h2>");
        _.each(this.collection.models, function(query) {
          return self.appendChild(query);
        });
        return this;
      }
    });
  });

}).call(this);
