// Generated by CoffeeScript 1.6.3
(function() {
  window.GoogleMap = function() {
    this.mapOptions = {
      center: new google.maps.LatLng(35, -62),
      zoom: 2,
      styles: themes[window.user.mapStyle] || themes['gMapRetro'],
      mapTypeControl: false,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      zoomControlOptions: {
        position: google.maps.ControlPosition.LEFT_CENTER
      },
      panControlOptions: {
        position: google.maps.ControlPosition.LEFT_CENTER
      }
    };
    this.map = new google.maps.Map(document.getElementById("map-canvas"), this.mapOptions);
    this.addClusterListeners();
    this.infowindow = new google.maps.InfoWindow();
    this.markers = [];
    return this;
  };

  window.GoogleMap.prototype.plot = function(story) {
    var j, markerIcon, self;
    j = story.toJSON();
    if (!((j.lat == null) || (j.lng == null) || typeof j.lat === "undefined" || typeof j.lng === "undefined")) {
      story.marker = new views.MapMarker({
        model: story,
        map: this.map
      }).render();
      markerIcon = story.marker.marker;
      this.bindEventsOnMarker(story.marker);
      markerIcon.setMap(this.map);
      this.markers.push(markerIcon);
      self = this;
      story.set("hasLocation", true);
    } else {
      story.set("hasLocation", false);
    }
    story.trigger("doneloading");
    return this;
  };

  window.GoogleMap.prototype.clear = function() {
    _.each(this.markers, function(marker) {
      return marker.setMap(null);
    });
    return this;
  };

  window.GoogleMap.prototype.bindEventsOnMarker = function(markerObj) {
    var display, self;
    display = markerObj.$el.html();
    self = this;
    google.maps.event.addListener(markerObj.marker, "click", function() {
      return markerObj.model.trigger("showpopup");
    });
    google.maps.event.addListener(markerObj.marker, "mouseover", function() {
      return markerObj.model.trigger("highlight");
    });
    google.maps.event.addListener(markerObj.marker, "mouseout", function() {
      return markerObj.model.trigger("unhighlight");
    });
    return this;
  };

  window.GoogleMap.prototype.addClusterListeners = function() {
    var self;
    self = this;
    return google.maps.event.addListener(this.map, 'zoom_changed', function() {
      var markers, zoom;
      zoom = self.map.getZoom();
      markers = self.markers;
      console.log(zoom);
      if (zoom > 6) {
        return _.each(markers, function(marker) {
          return $(marker.label.labelDiv_).text("dfsfdsd");
        });
      } else {
        return _.each(markers, function(marker) {
          return $(marker.label.labelDiv_).addClass("hidden");
        });
      }
    });
  };

}).call(this);