<!DOCTYPE html>
<html>
  <head>
    <title>News Map</title>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
    <link href='http://fonts.googleapis.com/css?family=Oswald:400,300' rel='stylesheet' type='text/css'>
    <link rel='stylesheet' media='screen' href='stylesheets/screen.css' />
    <script src="https://www.google.com/jsapi"></script>
    <script type='text/javascript' src='http://code.jquery.com/jquery-2.0.0.min.js'></script>
    <script type="text/javascript"
      src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBoS1bfOyPBTbYH1GhtD4xRs9XrT17nGwg&sensor=true">
    </script>
    <script type='text/javascript' src='storymap.js'></script>
  </head>
  <body>
    <div class='wrap'>
      <div id='search'>
        <input placeholder='Search for a news story to map.' type='text' name='news-term' id='news-search' value='London, England' />
        <button class='go' id='go'>Search <span class='icon s9'>v</span> </button>
      </div>
      <div id="map-canvas"></div>
    </div>
    <ul class='sidenav'>
      <li>Your Maps</li>
      <li></li>
      <li></li>
      <li></li>
      <li></li>
    </ul>
  </body>
</html>