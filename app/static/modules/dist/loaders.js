(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(["hub", "stories"], function(hub, stories) {
    var FeedAnalysisProgress, ProgressFactory, Progressbar, SVG, SpinningLoader, transitionFn;
    SpinningLoader = (function() {
      function SpinningLoader() {
        this;
      }

      SpinningLoader.prototype.get = function() {
        return '<div class="spinner"><div class="rect1"></div><div class="rect2"></div><div class="rect3"></div><div class="rect4"></div><div class="rect5"></div></div>';
      };

      return SpinningLoader;

    })();
    transitionFn = function(diff, currentVal, step, count) {
      var args;
      this.el.attr("value", currentVal + step);
      currentVal += step;
      args = arguments;
      if (count > this.totalSteps) {
        return cancelAnimationFrame(this.animationFrame);
      } else {
        return requestAnimationFrame((function(_this) {
          return function() {
            count++;
            return transitionFn.apply(_this, args);
          };
        })(this));
      }
    };
    Progressbar = (function() {
      Progressbar.prototype.reset = function() {
        return this.el.attr("value", 0);
      };

      Progressbar.prototype.getDefaultBar = function() {
        return $("<progress min='0' max='100' value='0' class='hidden'></progress>");
      };

      function Progressbar(el, number) {
        this.el = el;
        this.number = number != null ? number : 0;
        _.extend(this, Backbone.Events);
        _.bindAll(this, "set");
        this.animationFrame = null;
        if (this.el == null) {
          this.el = this.getDefaultBar();
        }
        this;
      }

      Progressbar.prototype.createListener = function() {
        return this.listener = new FeedAnalysisProgress(this.el, this.name);
      };

      Progressbar.prototype.max = 100;

      Progressbar.prototype.totalSteps = 20;

      Progressbar.prototype.get = function() {
        return parseInt(this.el.attr("value"));
      };

      Progressbar.prototype.reset = function() {
        this.stop();
        return this.el.attr("value", 0);
      };

      Progressbar.prototype.show = function() {
        this.el.slideDown("fast");
        this.number.fadeIn("fast");
        return this;
      };

      Progressbar.prototype.hide = function() {
        this.number.fadeOut("fast");
        this.el.slideUp("fast");
        return this;
      };

      Progressbar.prototype.set = function(val, count, diff) {
        var currentVal, step, transition;
        if (count == null) {
          count = 0;
        }
        currentVal = parseInt(this.el.attr("value"));
        diff = val - currentVal;
        step = diff / this.totalSteps;
        return transition = requestAnimationFrame((function(_this) {
          return function() {
            return transitionFn.call(_this, diff, currentVal, step, 0);
          };
        })(this));
      };

      Progressbar.prototype.setText = function(text) {
        return this.number.text(text);
      };

      Progressbar.prototype.updatePercentage = function(newPercentage) {
        this.set(newPercentage);
        return this;
      };

      return Progressbar;

    })();
    FeedAnalysisProgress = (function(_super) {
      __extends(FeedAnalysisProgress, _super);

      function FeedAnalysisProgress(el, name) {
        this.el = el;
        this.name = name;
      }

      FeedAnalysisProgress.prototype.monitorChanges = function(requestObj, name) {
        requestObj.on("addedStories:" + name, function() {});
        return requestObj.on("retrieval_" + name + ":done", (function(_this) {
          return function() {
            var activeStories, group, totalStoriesRetrieved;
            totalStoriesRetrieved = requestObj.totalStoriesRetrieved[name];
            activeStories = stories.getActiveSet();
            group = activeStories.getGroup(name);
            return group.on("done:analysis", function() {
              totalStoriesRetrieved.analyzed += 1;
              console.log(totalStoriesRetrieved);
              _this.updatePercentage(totalStoriesRetrieved.analyzed / totalStoriesRetrieved.retrieved);
              if (totalStoriesRetrieved.analyzed >= totalStoriesRetrieved.retrieved) {
                return setTimeout(function() {
                  var _ref;
                  return (_ref = _this.el.li) != null ? _ref.fadeOut("fast", function() {
                    return this.remove();
                  }) : void 0;
                }, 2400);
              }
            });
          };
        })(this));
      };

      FeedAnalysisProgress.prototype.render = function() {
        var li;
        return hub.getRegion("feedLoaderWrapper").$el.append(li = $("<li/>").html(this.el).attr("data-name", this.name));
      };

      FeedAnalysisProgress.prototype.updatePercentage = function(newPercentage) {
        return this.el.set(this.el.max * 100);
      };

      return FeedAnalysisProgress;

    })(Progressbar);
    SVG = (function() {
      var loaderDimension, svgNS, _colors;
      svgNS = "http://www.w3.org/2000/svg";
      loaderDimension = 100;
      _colors = {
        google: "white",
        yahoo: "yellow"
      };
      return function(name) {
        var img, rect, svg;
        svg = document.createElementNS(svgNS, "svg");
        svg.setAttribute("xmlns:xlink", "http://www.w3.org/1999/xlink");
        svg.setAttribute("height", loaderDimension);
        svg.setAttribute("width", loaderDimension);
        svg.setAttribute("class", "feed-loader");
        rect = document.createElementNS(svgNS, "rect");
        rect.setAttribute("height", loaderDimension);
        rect.setAttribute("width", loaderDimension);
        rect.setAttribute("fill", _colors[name]);
        rect.setAttribute("y", loaderDimension);
        img = document.createElementNS(svgNS, "image");
        img.setAttributeNS('http://www.w3.org/1999/xlink', 'href', "./static/images/" + name + "_loader.png");
        img.setAttribute("height", loaderDimension);
        img.setAttribute("width", loaderDimension);
        svg.appendChild(rect);
        svg.appendChild(img);
        return {
          svg: svg,
          listener: new FeedAnalysisProgress(svg, name),
          set: function(newPercentage) {
            rect = svg.childNodes[0];
            return rect.setAttribute("y", loaderDimension - newPercentage * 100);
          },
          max: function() {
            return parseInt(svg.getAttribute("height"));
          }
        };
      };
    })();
    ProgressFactory = (function() {
      function ProgressFactory() {}

      ProgressFactory.prototype.getFeed = function(type, name) {
        var p;
        p = new Progressbar();
        p.el.addClass(name);
        p.createListener();
        return p;
      };

      ProgressFactory.prototype.getBar = function() {
        return new Progressbar();
      };

      ProgressFactory.prototype.getSpinner = function() {
        return new SpinningLoader().get();
      };

      ProgressFactory.prototype.get = function(type, name) {
        switch (type) {
          case "feedAnalysis":
            return this.getFeed.apply(this, arguments);
          case "generic":
            return this.getBar.apply(this, arguments);
          case "spinner":
            return this.getSpinner.apply(this, arguments);
        }
      };

      return ProgressFactory;

    })();
    return ProgressFactory;
  });

}).call(this);
