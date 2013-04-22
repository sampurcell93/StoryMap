$(document).ready(function() {
	$("#date-slider").slider();
	var stories = [];
	function Map() {
		var mapOptions = {
        	center: new google.maps.LatLng(0,0),
        	zoom: 2,
        	mapTypeId: google.maps.MapTypeId.ROADMAP
        };
        var map = new google.maps.Map(document.getElementById("map-canvas"),
        	mapOptions);
        this.mapOptions = mapOptions;
        this.map = map;
        this.markers = [];
		this.infowindow = new google.maps.InfoWindow();

	};	
	Map.prototype.plotStory = function(story) {
		var xOff = Math.random() * 0.1;
		var yOff = Math.random() * 0.1;
		// console.log(story);
		var pt = new google.maps.LatLng(parseInt(story.latitude) + xOff,parseInt(story.longitude) + yOff);
		var display_string = "<h3><a target='_blank' href='" + story.unescapedUrl + "'>" + story.title + "</a></h3>" + "<p>" + story.content + "</p>";
		var marker = new google.maps.Marker({position: pt, title: story.title});
		this.markers.push(marker);
		marker.setMap(this.map);
		var that = this;
		google.maps.event.addListener(marker, 'click', function() {
			that.infowindow.setContent(display_string);	
			that.infowindow.open(that.map, this);
		});
	}

	Map = new Map();
	var $search = $("#news-search");
	var $go = $("#go");

	$search.focus().data("start_index",0).on("keydown",function(e) {
		if (e.keyCode == 13 || e.which == 13){
			$go.trigger("click");
			return;
		}
		$(this).data("start_index", $(this).data("start_index") + 1);
		console.log(stories);
	});

	$go.on("click", function() {
		for (var m in Map.markers) {
			Map.markers[m].setMap(null);
		}
		end = false;
		for (var i = 0; i <= 12 && !end; i+=4)
			getNews(i);
			
	})

	function getNews(start) {
		$.get("./getnews.php", 
			{
				q: $search.val(),
				start: start
			}, function(data) {	
				console.log(data);
				var json = JSON.parse(data);
				if (json.responseDetails == "out of range start"){
					end = true;
					return;
				}
				for (var i = 0; i < json.responseData.results.length; i++ )
						getData(json.responseData.results[i]);
			});
	}
	function getData(content) {
		var json;
		console.log("getting data");
		var context = content.titleNoFormatting + content.content;
		$.get("./calais.php",
		{
			content: context
		}, function(data) {
			json = JSON.parse(data);
			if (json == null)return;
		
			for (var el in json) {
				if (json[el].hasOwnProperty("resolutions")){
					console.log("has location!");
					content.latitude = json[el].resolutions[0].latitude;
					content.longitude = json[el].resolutions[0].longitude;
					stories.push(content);
					Map.plotStory(content);
					return;
				}
			}
		});
		return content;
	}
	function makeUIDialog(message) {
		$(document.body).append("<div class='ui-dialog'>" + message + "</div>").addClass("active-message");
		$(".ui-dialog").hide().fadeIn("fast", function() {
			$(this).delay(8000).fadeOut(800, function() { 
				$(this).remove();
				$(document.body).removeClass("active-message");
			});
		})
	}
})