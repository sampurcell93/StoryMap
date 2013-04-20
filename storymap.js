$(document).ready(function() {

	function Map() {
		var mapOptions = {
        	center: new google.maps.LatLng(0,0),
        	zoom: 2,
        	mapTypeId: google.maps.MapTypeId.ROADMAP
        };
        var map = new google.maps.Map(document.getElementById("map-canvas"),
        	mapOptions);
	};
	// if (navigator.geolocation) {
 //        navigator.geolocation.getCurrentPosition(function(position) {
 //                console.log(position);
 //                Map = new Map();
 //        }); 
	// }
	// else 
	Map = new Map();

	$("#news-search").focus().on("keydown",function(e) {
		if (e.keyCode == 13 || e.which == 13)
			$("#go").trigger("click");
	});

	$("#go").on("click", function() {
		$.get("./getnews.php", 
			{
				q: $("#news-search").val(),
				since: "1970-01-01"
			}, function(data) {
			console.log(data);
		})
	})
})