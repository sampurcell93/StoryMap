// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var $go, $search;
    $search = $("#news-search");
    $go = $("#go");
    $search.focus().on("keydown", function(e) {
      if (e.keyCode === 13 || e.which === 13) {
        $go.trigger("click");
        return;
      }
      return $(this).data("start_index", $(this).data("start_index") + 1);
    });
    $("#date-slider").slider();
    return $go.on("click", function() {
      var StoryMap, i, m, _i, _ref, _ref1, _results;
      StoryMap = window.StoryMap;
      StoryMap.numStories = 0;
      for (m in StoryMap.markers) {
        StoryMap.markers[m].setMap(null);
      }
      _results = [];
      for (i = _i = _ref = StoryMap.numStories, _ref1 = StoryMap.numStories + 12; _i <= _ref1; i = _i += 4) {
        _results.push(getGoogleNews($search.val(), i));
      }
      return _results;
    });
  });

}).call(this);
