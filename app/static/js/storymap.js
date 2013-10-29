// Generated by CoffeeScript 1.6.3
(function() {
  window.GoogleMap = function(model) {
    this.model = model;
    this.mapOptions = {
      center: new google.maps.LatLng(35, -62),
      zoom: 2,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    this.map = new google.maps.Map(document.getElementById("map-canvas"), this.mapOptions);
    this.infowindow = new google.maps.InfoWindow();
    this.markers = model.get("markers") || [];
    return this;
  };

  window.GoogleMap.prototype.plot = function(story) {
    var display, j, marker, that;
    j = story.toJSON();
    if (!(typeof j.latitude === "undefined" || j.longitude === "undefined")) {
      marker = new views.MapMarker({
        model: story,
        map: this.map
      });
      display = marker.render().$el.html();
      marker = marker.marker;
      this.markers.push(marker);
      marker.setMap(this.map);
      story.marker = marker;
      that = this;
      google.maps.event.addListener(marker, "click", function() {
        that.infowindow.setContent(display);
        return that.infowindow.open(that.map, this);
      });
    }
    return this;
  };

}).call(this);
