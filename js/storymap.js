// Generated by CoffeeScript 1.6.3
(function() {
  window.launchModal = function(content) {
    var modal;
    modal = $("<div />").addClass("modal");
    if ($.isArray(content)) {
      _.each(content, function(item) {
        return modal.append(item);
      });
    } else {
      modal.html(content);
    }
    modal.prepend("<i class='close-modal icon-untitled-7'></i>");
    $(document.body).addClass("active-modal").append(modal);
    return modal;
  };

  window.GoogleMap = function(model) {
    var map;
    this.mapOptions = {
      center: new google.maps.LatLng(0, 0),
      zoom: 2,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    };
    map = new google.maps.Map(document.getElementById("map-canvas"), this.mapOptions);
    this.map = map;
    this.markers = [];
    this.infowindow = new google.maps.InfoWindow();
    if (model != null) {
      this.model = model;
    }
    return this;
  };

  window.GoogleMap.prototype.plotStory = function(story) {
    var display_string, marker, pt, that, xOff, yOff;
    xOff = Math.random() * 0.1;
    yOff = Math.random() * 0.1;
    pt = new google.maps.LatLng(parseInt(story.latitude) + xOff, parseInt(story.longitude) + yOff);
    display_string = "<h3><a target='_blank' href='" + story.unescapedUrl + "'>" + story.title + "</a></h3>" + "<p>" + story.content + "</p>";
    marker = new google.maps.Marker({
      position: pt,
      title: story.title
    });
    this.markers.push(marker);
    marker.setMap(this.map);
    that = this;
    return google.maps.event.addListener(marker, "click", function() {
      that.infowindow.setContent(display_string);
      return that.infowindow.open(that.map, this);
    });
  };

}).call(this);
