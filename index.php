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
      <div class="fr w4" style='border: 1px solid red;'>
        <button class='go fr' id='go'>Search <span class='s9 icon-search'></span> </button>  
        <input placeholder='Search the news' type='text' name='news-term' class='fr' id='news-search' value='Invasive Species' />
      </div>
      <ul class='fr w6'>
        <li>Saved</li>
        <li></li>
        <li></li>
        <li></li>
      </ul>

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