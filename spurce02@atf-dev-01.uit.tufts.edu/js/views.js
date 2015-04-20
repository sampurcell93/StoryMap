// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var blueIcon, redIcon;
    blueIcon = "static/images/bluepoi.png";
    redIcon = "static/images/redpoi.png";
    window.views = {};
    window.views.MapItem = Backbone.View.extend({
      el: 'section.map',
      typeahead: false,
      url: function() {
        return '/favorite?user_id=' + this.model.user.id + "&query_id=" + this.currQuery.id;
      },
      initialize: function() {
        var $searchbar, Underscore, self,
          _this = this;
        _.bindAll(this, "render", "toggleMarkers", "search");
        self = this;
        this.model.instance = this;
        this.on({
          "loading": this.createLoadingOverlay,
          "doneloading": function() {
            return window.destroyModal();
          }
        });
        this.listenTo(this.model, "change:title", function(model, title) {
          return self.$(".js-news-search").typeahead('setQuery', title);
        });
        window.mapObj = self.mapObj = this.model.map;
        $searchbar = self.$(".js-news-search");
        if (!this.typeahead) {
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
          $.get("/queries", {}, function(response) {
            _.each(response.queries, function(r) {
              r.value = r.title;
              return r.tokens = [r.title];
            });
            $searchbar.typeahead([
              {
                name: 'Queries',
                template: $("#existing-query-item").html(),
                local: response.queries,
                engine: Underscore,
                limit: 1000
              }
            ]);
            return _this.typeahead = true;
          });
        }
        this.timeline = new views.Timeline({
          collection: this.model.get("stories"),
          map: this
        });
        this.storyList = new views.StoryList({
          collection: this.model.get("stories"),
          map: this,
          timeline: this.timeline
        });
        this.render();
        return this;
      },
      render: function() {
        this.$(".js-news-search").typeahead('setQuery', this.model.get("title") || "");
        this.renderComponents();
        return this.plotAll();
      },
      plotAll: function() {
        _.each(this.model.get("stories").models, function(story) {
          return story.plot();
        });
        return this;
      },
      renderComponents: function() {
        if (this.storyList != null) {
          this.storyList.render();
        }
        if (this.timeline != null) {
          this.timeline.reset().updateHandles(true).render();
        }
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
      cacheQuery: function(query) {
        existingQueries._byTitle[query.get("title")] = query;
        return this;
      },
      search: function(query) {
        var queryobj, self,
          _this = this;
        this.$(".icon-in").css("visibility", "visible");
        self = this;
        queryobj = new models.Query({
          title: query
        });
        this.model = queryobj;
        this.storyList.collection = this.timeline.collection = queryobj.get("stories");
        this.timeline.reset().render();
        this.storyList.bindListeners();
        this.cacheQuery(queryobj);
        this.trigger("loading");
        mapObj.clear();
        return queryobj.exists((function(model) {
          return app.navigate("query/" + model, true);
        }), (function(query) {
          $(".js-save-query").removeClass("hidden");
          return queryobj.getGoogleNews(0, queryobj.getFeedZilla(queryobj.getYahooNews(0, function() {
            window.destroyModal();
            window.existingQueries.add(queryobj);
            _this.timeline.reset().updateHandles(true).render();
            return queryobj.analyze();
          })));
        }));
      },
      loadQuery: function(query) {
        var model, self;
        model = query || this.model;
        self = this;
        return model.fetch({
          success: function(model, resp, options) {
            var formatted;
            window.mapObj.clear();
            formatted = model.attributes;
            formatted.stories = new collections.Stories(resp["stories"].models, {
              parse: true
            });
            self.model = query;
            self.storyList.collection = self.timeline.collection = formatted.stories;
            self.render();
            return destroyModal();
          },
          error: function() {}
        });
      },
      events: {
        "click .js-toggle-analytics": function(e) {
          return cc("analytics on the way thoooo");
        },
        "keydown .js-news-search": function(e) {
          var key, val;
          key = e.keyCode || e.which;
          val = $(e.currentTarget).val();
          if (key === 13) {
            return this.search(val);
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
        "click .js-save-query": function(e) {
          var stories, toSave;
          toSave = this.model;
          stories = toSave.get("stories");
          return toSave.save(null, {
            success: function(resp, b, c) {
              var len;
              toSave.favorite();
              toSave.set("stories", stories);
              len = stories.length;
              _.each(stories.models, function(story, i) {
                story.set("query_id", toSave.id);
                return story.save(null, {
                  success: function(resp) {
                    console.log(i);
                    if (i === len - 1) {
                      launchModal("<h2 class='center'>Saved Query!</h2>");
                      return setTimeout(destroyModal, 1000);
                    }
                  }
                });
              });
              return {
                error: function() {
                  return cc("Something went wrong when saving the stories");
                }
              };
            }
          });
        }
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
        _.bindAll(this, "render");
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
          },
          "showpopup": function() {
            if ((this.marker != null) && this.map.getZoom() >= 7) {
              return this.map.setCenter(this.marker.getPosition());
            }
          },
          "center": function() {
            if (this.marker != null) {
              return this.map.setCenter(this.marker.getPosition());
            }
          }
        });
      },
      render: function() {
        var pt, xOff, yOff;
        this.$el.html(_.template(this.template, this.model.toJSON()));
        this.xoff = xOff = Math.random() * 0.1;
        this.yoff = yOff = Math.random() * 0.1;
        pt = new google.maps.LatLng(parseFloat(this.model.get("lat")) + xOff, parseFloat(this.model.get("lng")) + yOff);
        this.marker = new MarkerWithLabel({
          position: pt,
          animation: google.maps.Animation.DROP,
          title: this.model.get("title"),
          icon: redIcon,
          map: window.mapObj.map,
          labelContent: this.model.get("date").cleanFormat(),
          labelClass: 'map-label hidden',
          labelAnchor: new google.maps.Point(32, 0)
        });
        return this;
      }
    });
    window.views.QuickStory = Backbone.View.extend({
      template: $("#quick-story-popup").html(),
      className: 'quick-story',
      tagName: 'dl',
      render: function() {
        this.$el.html(_.template(this.template, this.model.toJSON()));
        return this;
      },
      events: {
        click: function() {
          return this.model.trigger("center");
        }
      }
    });
    window.views.StoryListItem = (function() {
      var GeoItem, GeoList;
      GeoItem = Backbone.View.extend({
        tagName: 'li',
        template: $("#geocode-choice").html(),
        initialize: function(attrs) {
          _.extend(this, attrs);
          return this;
        },
        render: function() {
          this.$el.html(_.template(this.template, this.bareobj));
          return this;
        },
        events: {
          click: function() {
            var geo,
              _this = this;
            cc(this.story);
            cc(this.bareobj);
            if (this.story) {
              geo = this.bareobj.geometry.location;
              return this.story.save({
                lat: geo.lat,
                lng: geo.lng,
                location: this.bareobj.formatted_address
              }, {
                success: function(response) {
                  _this.$el.addClass("icon-location-arrow");
                  return setTimeout(function() {
                    destroyModal();
                    _this.story.set("hasLocation", true);
                    return _this.story.plot();
                  }, 1400);
                }
              });
            }
          }
        }
      });
      GeoList = Backbone.View.extend({
        el: "ul.geocode-choices",
        initialize: function(attrs) {
          _.bindAll(this, "render", "append");
          _.extend(this, attrs);
          this.render();
          return this;
        },
        append: function(loc) {
          var item;
          if (loc.geometry == null) {
            return this;
          }
          item = new GeoItem({
            bareobj: loc,
            story: this.story
          });
          this.$el.append(item.render().el);
          return this;
        },
        render: function() {
          var s;
          s = this.locs.length === 1 ? "" : "s";
          this.$el.html("<li class='geo-header'>We found " + this.locs.length + " possible location" + s + "</li>");
          _.each(this.locs, this.append);
          return this;
        }
      });
      return Backbone.View.extend({
        template: $("#article-item").html(),
        tagName: 'li',
        enterLocTemplate: $("#enter-loc").html(),
        initialize: function(attrs) {
          var self;
          this.popup = new views.QuickStory({
            model: this.model
          });
          _.bindAll(this, "render", "getPosition", "togglePopup");
          _.extend(this, attrs);
          self = this;
          return this.listenTo(this.model, {
            "save": function() {
              return cc("SAVED THIS BITCH");
            },
            "hide": function() {
              console.log("hiding");
              return this.$el.hide();
            },
            "show": function() {
              console.log("showing");
              return this.$el.show();
            },
            "loading": function() {
              return this.$el.addClass("loading");
            },
            "change:hasLocation": function(model, hasLocation) {
              if (hasLocation) {
                return this.$el.removeClass("no-location").addClass("has-location");
              } else {
                return this.$el.removeClass("has-location").addClass("no-location");
              }
            },
            "doneloading": function() {},
            "highlight": function() {
              return this.$el.addClass("highlighted");
            },
            "unhighlight": function() {
              return this.$el.removeClass("highlighted");
            },
            "showpopup": this.togglePopup
          });
        },
        launchLocationPicker: function() {
          var getLocs, iface,
            _this = this;
          iface = _.template(this.enterLocTemplate, {
            title: this.model.escape("title").stripHTML()
          });
          iface = launchModal(iface);
          getLocs = function() {
            var loader;
            loader = $("<p/>").addClass("center loading-geocode-text").text("Loading.....");
            iface.append(loader);
            return _this.model.geocode(iface.find(".js-address-value").val(), {
              success: function(coords) {
                var list;
                list = new GeoList({
                  locs: coords,
                  story: _this.model
                });
                return loader.remove();
              },
              error: function() {
                loader.remove();
                return setTimeout(window.destroyModal, 1500);
              }
            });
          };
          iface.find(".js-address-value").focus().on("keydown", function(e) {
            var key;
            key = e.keyCode || e.which;
            if (key === 13) {
              return getLocs();
            }
          });
          return iface.find(".js-geocode-go").on("click", function() {
            return getLocs();
          });
        },
        getPosition: function() {
          return this.$el.position().top;
        },
        togglePopup: function() {
          var self;
          self = this;
          this.popup.render();
          $(".quick-story").not(this.popup.el).slideUp("fast");
          return this.popup.$el.slideToggle("fast", function() {
            var $parent, pos;
            $parent = self.$el.parent("ol");
            pos = self.getPosition() + $parent.scrollTop() - 100;
            return $parent.animate({
              scrollTop: pos
            }, 300);
          });
        },
        render: function() {
          if (this.model.hasLocation()) {
            this.$el.addClass("has-location");
          } else {
            this.$el.addClass("no-location");
          }
          this.$el.append(_.template(this.template, this.model.toJSON()));
          this.$el.append($(this.popup.render().el).hide());
          return this;
        },
        events: {
          "dblclick .article-title": function() {
            var w;
            w = window.open(this.model.get("url"), "_blank");
            return w.focus();
          },
          "click .article-title": function(e) {
            return this.togglePopup(e);
          },
          "mouseover": function() {
            return this.model.trigger("highlight");
          },
          "mouseout": function() {
            return this.model.trigger("unhighlight");
          },
          "click .js-set-location": "launchLocationPicker",
          "click .js-show-model": "togglePopup",
          "click .js-zoom-to-date": function() {
            return this.timeline.zoomTo(this.model.get("date"));
          }
        }
      });
    })();
    window.views.StoryList = Backbone.View.extend({
      el: '.all-articles',
      list: 'ol.article-list',
      sortopts: '.sort-options-list',
      hidden: false,
      events: {
        "click": function() {
          return cc(this.collection);
        }
      },
      initialize: function(attrs) {
        var self;
        self = this;
        this.map = this.options.map;
        _.extend(this, attrs);
        _.bindAll(this, "render", "appendChild", "toggle", "filter");
        return this.bindListeners();
      },
      bindListeners: function() {
        var self;
        self = this;
        this.render();
        return this.listenTo(this.collection, "add", function(model) {
          return self.appendChild(model);
        });
      },
      appendChild: function(model) {
        var view;
        console.log(model.get("title"));
        view = new views.StoryListItem({
          model: model,
          timeline: this.timeline
        });
        this.$(this.list).find(".placeholder").remove().end().append(view.render().el);
        return this;
      },
      render: function() {
        var self;
        self = this;
        this.$(this.list).children().not(".placeholder").remove();
        _.each(this.collection.models, function(model) {
          return self.appendChild(model);
        });
        return this;
      },
      filterFns: {
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
      },
      filter: function(param, show, closure) {
        var filterFn;
        filterFn = this.filterFns[param];
        _.each(this.collection.models, function(story) {
          var filter;
          filter = filterFn(story, closure);
          if (filter && show === false) {
            story.trigger("hide");
            return story.filteredout = true;
          } else if (filter && show === true) {
            story.trigger("show");
            return story.filteredout = false;
          }
        });
        return this;
      },
      sortFns: {
        "newest": function(model) {
          return -model.get("date");
        },
        "oldest": function(model) {
          return model.get("date");
        }
      },
      toggle: function() {
        var map, smoothRender, startTime;
        cc("Toggling");
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
        }, 3);
      },
      events: {
        "keyup .js-filter-articles": function(e) {
          var $t, val;
          val = ($t = $(e.currentTarget)).val().toLowerCase();
          return _.each(this.collection.models, function(story) {
            if (story.get("title").toLowerCase().indexOf(val) !== -1 && !story.filteredout) {
              return story.trigger("show");
            } else {
              return story.trigger("hide");
            }
          });
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
          show = $t.data("showing");
          if (typeof show === "undefined") {
            show = false;
          }
          $t.data("showing", !show);
          return this.filter($t.data("param"), !$t.data("showing"));
        },
        'click .js-sort': function(e) {
          var $siblings, $t;
          $t = $(e.currentTarget);
          $t.addClass("active");
          $siblings = $t.siblings(".active");
          $siblings.each(function() {
            return $(this).trigger("switch");
          });
          this.collection.comparator = this.sortFns[$t.data("sort")];
          this.collection.sort();
          return this.render();
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
      initialize: function() {
        var self, update_val;
        self = this;
        this.map = this.options.map;
        _.bindAll(this, "render", "addMarker", "changeValue", "play", "stop", "updateHandles");
        this.listenTo(this.collection, "change:location", function() {
          return cc(arguments);
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
      reset: function() {
        this.min = this.max = void 0;
        return this;
      },
      clearMarkers: function() {
        this.$(".timeline-marker").remove();
        return this;
      },
      render: function() {
        var self;
        self = this;
        this.clearMarkers();
        _.each(this.collection.models, function(story) {
          return self.addMarker(story);
        });
        return this;
      },
      addMarker: function(model) {
        var $slider, pixeladdition, pos, range, view, width;
        cc("appending a MARKR ONTO TIMELINE");
        $slider = this.$(".slider-wrap");
        width = $slider.width();
        pos = new Date(model.get("date")).getTime();
        range = this.max - this.min;
        pos -= this.min;
        pos /= range;
        pixeladdition = 10 / width;
        view = new views.TimelineMarker({
          model: model,
          left: pos
        });
        $slider.append(view.render().el);
        return this;
      },
      play: function() {
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
      },
      stop: function() {
        this.isPlaying = false;
        this.$(".js-pause-timeline").trigger("switch");
        return this;
      },
      toEnd: function() {
        var $tl, end;
        $tl = this.$timeline;
        this.stop();
        end = $tl.slider("option", "max");
        $tl.slider("values", 1, end);
        return end;
      },
      toStart: function() {
        var $tl, start;
        $tl = this.$timeline;
        this.stop();
        start = $tl.slider("values", 0);
        $tl.slider("values", 1, start);
        return start;
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
      updateHandles: function() {
        var $timeline, handles, max, maxdate, min, mindate, prevcomparator;
        if (this.collection.length < 2) {
          return this;
        }
        prevcomparator = this.collection.comparator;
        this.collection.comparator = function(model) {
          return model.get("date");
        };
        this.collection.sort();
        this.min = min = this.collection.first().get("date");
        this.max = max = this.collection.last().get("date");
        if (max instanceof Date === false) {
          this.max = max = new Date(max);
        }
        if (min instanceof Date === false) {
          this.min = min = new Date(min);
        }
        mindate = parseInt(min.getTime());
        maxdate = parseInt(max.getTime());
        $timeline = this.$timeline;
        handles = $timeline.find(".ui-slider-handle");
        handles.first().data("display-date", min.cleanFormat());
        handles.last().data("display-date", max.cleanFormat());
        $timeline.slider("option", {
          min: mindate,
          max: maxdate
        });
        $timeline.slider("values", 0, mindate);
        $timeline.slider("values", 1, maxdate);
        this.max = this.max.getTime();
        this.min = this.min.getTime();
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
      zoomTo: function(date) {
        var $t, center, high, low, offset, offsetH, offsetL;
        if (!this.min || !this.max) {
          return this;
        }
        center = (new Date(date)).getTime();
        offsetL = (this.max - center) / 2;
        offsetH = (center - this.min) / 2;
        offset = offsetL > offsetH ? offsetH : offsetL;
        $t = this.$timeline;
        low = parseInt(center - offset);
        high = parseInt(center + offset);
        $t.slider("values", 0, low);
        $t.slider("values", 1, high);
        return this;
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
        "click .js-to-end": "toEnd",
        "click .js-to-start": "toStart",
        "mouseover .timeline-controls li": function(e) {
          var $t;
          return $t = $(e.currentTarget);
        }
      }
    });
    window.views.TimelineMarker = Backbone.View.extend({
      className: 'timeline-marker',
      template: $("#date-bubble").html(),
      initialize: function() {
        return this.listenTo(this.model, {
          "hide": function() {
            return this.$el.hide();
          },
          "show": function() {
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
      },
      render: function() {
        var $el, num;
        num = this.options.left;
        $el = this.$el;
        $el.css('left', (num * 100) + "%");
        $el.html(_.template(this.template, {
          date: new Date(this.model.get("date")).cleanFormat()
        }));
        if (!this.model.hasLocation()) {
          $el.addClass("no-location-marker");
        }
        this.$(".date-bubble").hide();
        return this;
      },
      events: {
        "mouseover": function() {
          return this.model.trigger("highlight");
        },
        "mouseout": function() {
          return this.model.trigger("unhighlight");
        },
        "click": function(e) {
          return this.model.trigger("showpopup");
        }
      }
    });
    window.views.QueryThumb = (function() {
      var i, randClasses;
      i = 0;
      randClasses = ["blueribbon", "green", "orangestuff", "pink", "purple", "angle"];
      return Backbone.View.extend({
        tagName: 'li',
        template: $("#query-thumb").html(),
        searchComplete: function() {
          return console.log(arguments);
        },
        render: function() {
          this.$el.html(_.template(this.template, this.model.toJSON())).addClass(randClasses[i++ % 6]);
          return this;
        },
        events: {
          "click .js-load-map": function() {
            return window.app.navigate("/query/" + this.model.get("title"), true);
          }
        }
      });
    })();
    return window.views.QueryThumbList = Backbone.View.extend({
      tagName: 'ul',
      className: 'query-thumb-list',
      template: $("#query-list-help").html(),
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
        this.$el.html(_.template(this.template, {}));
        _.each(this.collection.models, function(query) {
          return self.appendChild(query);
        });
        return this;
      }
    });
  });

}).call(this);