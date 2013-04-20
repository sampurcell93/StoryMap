$(document).ready(function() {

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
	};	
	Map.prototype.plotStories = function(stories) {
		console.log(stories.responseData);

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
	});

	$go.on("click", function() {
		getNews(0);
		getData();
	})

	function getNews(start) {
		$.get("./getnews.php", 
			{
				q: $search.val(),
				start: start
			},
		function(data) {
			Map.plotStories(JSON.parse(data));
		});
	}
	function getData() {
		var content = " yolo";
		var clfsws = new XMLHttpRequest();
        clfsws.open("POST", "http://api.opencalais.com/enlighten/rest/", true);
        clfsws.onreadystatechange = function() { console.log("here")};
        clfsws.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        clfsws.send("licenseID=c3wjfrkfmrsft3r5wgxm5skr&content=" + encodeURIComponent(content) + '&paramsXML=' + encodeURIComponent('<c:params xmlns:c="http://s.opencalais.com/1/pred/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"><c:processingDirectives c:contentType="text/txt" c:outputFormat="text/gnosis" c:discardMetadata=";"></c:processingDirectives><c:userDirectives c:allowDistribution="true" c:allowSearch="true" c:externalID="calaisbridge" c:submitter="calaisbridge"></c:userDirectives><c:externalMetadata c:caller="GnosisFirefox"/></c:params>'));
	}
})