<!DOCTYPE html>
<html>
  <head>
    <title>News Map</title>
    <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
    <link href='http://fonts.googleapis.com/css?family=Lato:300,400|Open+Sans:400,300' rel='stylesheet' type='text/css'>
    <link rel='stylesheet' media='screen' href='assets/stylesheets/screen.css' />
    <link rel='stylesheet' media='screen' href='assets/icomoon/style.css' />
  </head>
  <body>
    PWD
    <div class="map-instance-list">
      <script type='text/template' id='map-instance'>
        <header>
          <ul class="w4 fl control-panel ">
            <li><a class='icon-th-large' data-route='#saved'>Saved</a></li>
            <li><a class='icon-play js-play-timeline'  >Timeline</a></li>
            <li><a class='icon-settings' data-route='#settings'>Settings</a></li>
          </ul>
          <div class="fr w5  search-bar">
            <button class='go fr'>Search <i class='s9 icon-search'></i> </button>  
            <input placeholder='Search the news' type='text' name='news-term' class='fr news-search' />
          </div>
        </header>
        <div class='map-canvas' id='map-canvas'></div>
        <footer>
          <div class="timeline-slider" ></div> 
          <div class='timeline-marker'></div>
        </footer>
      </script>
    </div> <!-- end large container -->
    <script type="text/template" id='storymarker'>
      <% var u = "undefined" %>
      <h3>
        <a target='_blank' href='" + <%= typeof unescapedUrl !== u ? unescapedUrl : "" %> + "'><%= title %></a>
      </h3>
      <p><%= typeof content !== u ? content : "Sorry, we don't have a snippet here" %></p>
    </script>
    <?php include("./messages.php"); ?>
    <script type='text/javascript' src='js/jquery.js'></script>
    <script type='text/javascript' src='js/jqueryui.js'></script>
    <script type="text/javascript" src="https://maps.googleapis.com/maps/api/js?key=AIzaSyBoS1bfOyPBTbYH1GhtD4xRs9XrT17nGwg&sensor=true"></script>
    <script type='text/javascript' src='js/underscore.js'></script>
    <script type='text/javascript' src='js/backbone.js'></script>
    <script type='text/javascript' src='js/general.js'></script>
    <script type='text/javascript' src='js/models.js'></script>
    <script type='text/javascript' src='js/views.js'></script>
    <script type='text/javascript' src='js/storymap.js'></script>
  </body>
</html>