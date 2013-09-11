<!DOCTYPE html>
<html>
  <head>
    <title>News Map</title>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
    <link href='http://fonts.googleapis.com/css?family=Oswald:400,300' rel='stylesheet' type='text/css'>
    <link rel='stylesheet' media='screen' href='assets/stylesheets/screen.css' />
    <link rel='stylesheet' media='screen' href='assets/icomoon/style.css' />
    <!-- <link rel="stylesheet" type="text/css" href="http://code.jquery.com/ui/1.10.2/themes/smoothness/jquery-ui.css"> -->
  </head>
  <body>
    <header>
      <button class='go fr' id='go'>Search <span class='s9 icon-search'></span> </button>  
      <input placeholder='Search for a news story to map.' type='text' name='news-term' class='fr' id='news-search' value='Invasive Species' />
      <div class="clear"></div>
    </header>
    
    <!-- <div id="date-slider" class='slider'></div> -->
    <div id="map-canvas" class='map-canvas'></div>


    <script src="https://www.google.com/jsapi"></script>
    <script type='text/javascript' src='js/jquery.js'></script>
    <script type="text/javascript"
      src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBoS1bfOyPBTbYH1GhtD4xRs9XrT17nGwg&sensor=true">
    </script>
    <script type='text/javascript' src='js/underscore.js'></script>
    <script type='text/javascript' src='js/backbone.js'></script>
    <script type='text/javascript' src='js/models.js'></script>
    <script type='text/javascript' src='js/storymap.js'></script>
    <script type='text/javascript' src='js/events.js'></script>
  </body>
</html>