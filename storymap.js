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
		var content = "yolo";
		$.get("http://api.opencalais.com/enlighten/rest/",
		{
			content: encodeURIComponent(content),
			licenseId: encodeURIComponent('7m48vqma8cc9g9gxmbq3n42r'),
			paramsXML: encodeURIComponent('<c:params xmlns:c="http://s.opencalais.com/1/pred/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">' +
        			'<c:processingDirectives c:contentType="text/html" c:outputFormat="application/json" c:discardMetadata=";">' +
        			'</c:processingDirectives>' +
        			// '<c:userDirectives c:allowDistribution="true" c:allowSearch="true" c:externalID="calaisbridge" c:submitter="newsmap">' + 
        			// '</c:userDirectives>' +
        			// '<c:externalMetadata c:caller="GnosisFirefox"/>' +
        		'</c:params>')
		}, function(data) {
			console.log(data);
		})
	}
})