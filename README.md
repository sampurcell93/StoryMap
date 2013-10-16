NewsMap
=======

The NewsMap is an application which pulls stories from Google News, passes them to OpenCalais, and uses the returned data to visualize a location-time graph via the Google Maps API.

Languages:
==========

If you've already looked through the code, you might see a bunch of stuff you're not familiar with. I'll break it down real fast. 

_Stylesheets_: _Do not edit the.css files. Ever._ Look into installing [Compass](http://compass-style.org/), which will allow you to edit and save the .scss files, located at assets/sass. The styles are concatenated into screen.scss, but the files beginning with "_" are modules which screen.scss includes. So you can edit those and they'll get folded in. To set up a watcher for changes to scss files, run "compass watch assets" from the base dir.

_Javascript_: Same thing - _NEVER_ edit the .js files in /js. Only edit the coffee files in /coffee. In order to compile them, you'll need to download [Coffeescript](http://coffeescript.org/). The syntax is close to javascript, so the curve should be fairly shallow. To set up a watcher for the coffee, run "coffee -o js -cw coffee" from the base dir. We'll worry about concatenation and minimization later. 

_Conventions_: Keeping with the best practices of the day, it will make everyone's life easier to adhere to some coding conventions.

## Coffeescript 

1. Comment everything. Seriously. Use "#" for commenting. For long comments use "###"
2. USE 4 SPACES FOR INDENTATION, NOT TAB. DO DO DO. This will save you so much time with the compiler. Figure out how to do it in your editor of choice.

## SCSS

1. Make modules. If you find yourself writing SCSS that is all kinda unified but not really in any previously defined category, make a new file in assets/sass like "_filename.scss" and import it. It'll help organization immensely.
2. Includes go at the top of the block.

## Python/Flask
1. Backend is in python running the flask framework for a fully restful interface


Stay thirsty, my friends.
