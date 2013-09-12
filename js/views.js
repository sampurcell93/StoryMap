// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var $go, $search, AllMaps, AllMapsView;
    window.views = {};
    AllMaps = window.AllMaps;
    window.views.MapItem = Backbone.View.extend({
      tagName: 'section',
      template: $("#map-instance").html(),
      initialize: function() {
        _.bindAll(this, "render");
        this.model.instance = this;
        this.listenTo(this.model, {
          "updateDateRange": this.updateDateRange
        });
        return this.updateDateRange();
      },
      render: function() {
        this.$el.html(_.template(this.template, this.model.toJSON()));
        return this;
      },
      afterAppend: function() {
        var update_val;
        this.model.set("map", new window.GoogleMap(this.model));
        update_val = function(e, ui) {
          var display, handle, pos, range;
          handle = $(ui.handle);
          pos = handle.index() - 1;
          range = ui.values;
          display = $("<div/>").addClass("handle-display-value").text(range[pos]);
          return handle.find("div").remove().end().append(display);
        };
        this.$timeline = this.$(".timeline-slider");
        return this.$timeline.slider({
          range: true,
          values: [0, 100],
          start: update_val,
          change: update_val,
          slide: update_val
        });
      },
      updateDateRange: function() {
        var articles, max, min;
        cc("updating date range");
        articles = this.model.get("articles");
        if (articles.length > 0) {
          min = articles.at(0);
          max = articles.last();
          _.each(articles.models, function(article) {
            var date;
            date = article.get("date");
            if (date < min.get("date")) {
              return min = article;
            } else if (date > max.get("date")) {
              return max = article;
            }
          });
          cc(Math.abs(max.get("date")));
          cc(Math.abs(min.get("date")));
          return this.$timeline.slider("option", {
            min: min.get("date"),
            max: max.get("date")
          });
        }
      },
      events: {
        "click .go": function() {
          var start, _i, _results;
          cc(this.model);
          _results = [];
          for (start = _i = 0; _i <= 12; start = _i += 4) {
            cc(start);
            _results.push(this.model.getGoogleNews(this.$(".news-search").val(), start));
          }
          return _results;
        },
        "click [data-route]": function(e) {
          var $t, current_route, route;
          $t = $(e.currentTarget);
          route = $t.data("route");
          current_route = Backbone.history.fragment;
          return window.app.navigate(route, {
            trigger: true
          });
        }
      }
    });
    window.views.MapInstanceList = Backbone.View.extend({
      el: ".map-instance-list",
      initialize: function() {
        this.listenTo(this.collection, {
          add: this.addInstance
        });
        return this;
      },
      addInstance: function(model) {
        var instance, item;
        item = new window.views.MapItem({
          model: model
        });
        instance = $(item.render().el);
        instance.appendTo(this.$el);
        item.afterAppend();
        instance.siblings().hide();
        return this;
      }
    });
    AllMapsView = new window.views.MapInstanceList({
      collection: AllMaps
    });
    $search = $("#news-search");
    $go = $("#go");
    $search.focus().on("keydown", function(e) {
      if (e.keyCode === 13 || e.which === 13) {
        $go.trigger("click");
        return;
      }
      return $(this).data("start_index", $(this).data("start_index") + 1);
    });
    return window.app.navigate("/map/0", true);
  });

}).call(this);