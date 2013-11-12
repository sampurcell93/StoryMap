themes = window.themes = {}

themes['gmapCountryStyle'] = [
                    
    //////////
    // WATER
    //////////
    {
        featureType: "water",
        stylers: [
        {
            hue: "#00caff"
        },
{
            saturation: 20
        },
{
            lightness: -40
        }
        ]
    },
                    
    //////////
    // General Landscape
    //////////
    {
        featureType: "landscape.man_made", // Set the ground color in cities
        elementType: "geometry",
        stylers: [
        {
            visibility: "on"
        },
{
            hue: "#0096ff"
        },
{
            saturation: 20
        },
{
            lightness: 70
        }
        ]
    },
    {
        featureType: "landscape.natural", // Set the ground color in cities
        elementType: "geometry",
        stylers: [
        {
            visibility: "on"
        },
{
            hue: "#0096ff"
        },
{
            saturation: 30
        },
{
            lightness: 45
        }
        ]
    },
    {
        featureType: "administrative.land_parcel", // Remove borders between buildings
        stylers: [
        {
            visibility: "on"
        }
        ]
    },
    {
        featureType: "administrative.neighborhood", // Remove neighborhood labels
        stylers: [
        {
            visibility: "off"
        }
        ]
    },
    {
        featureType: "landscape.man_made",
        elementType: "labels",
        stylers: [
        {
            visibility: "off"
        }
        ]
    },
                    
    //////////
    // Point Of Interest
    //////////
                   
    {
        featureType: "poi.park",
        stylers: [
        {
            hue: "#57ff00"
        },
{
            saturation: -30
        },
{
            lightness: -32
        }
        ]
    },
    {
        featureType: "poi.business",
        stylers: [
        {
            visibility: "off"
        }
        ]
    },
    {
        featureType: "poi.sports_complex", // Remove sport area
        elementType: "labels",
        stylers: [
        {
            visibility: "off"
        }
        ]
    },
    {
        featureType: "poi.government",
        elementType: "labels",
        stylers: [
        {
            visibility: "off"
        }
        ]
    },
    {
        featureType: "poi.medical",
                        
        stylers: [
                            
        {
            visibility: "on"
        },
{
            hue: "#ff1b00"
        },
{
            saturation: 40
        },
{
            lightness: 10
        }
        ]
    },
    {
        featureType: "poi.school",
                        
        stylers: [
        {
            visibility: "on"
        },
{
            hue: "#ffbe00"
        },
{
            saturation: 50
        },
{
            lightness: 0
        }
        ]
    },
                    
                   
                    
    //////////
    // Roads
    //////////
    { 
        featureType: "road", 
        elementType: "labels",
        stylers: [ 
        {
            hue: "#000000"
        },
{
            saturation: -100
        },
{
            gamma: 2
        },
{
            visibility: "on"
        } 
        ]
    },
                    
{
        featureType: "road.arterial",
        elementType: "geometry",
        stylers: [
        {
            visibility: "simplified"
        },
{
            saturation: -100
        },
{
            hue: "#00fff7"
        },
{
            lightness: 00
        }
        ]
    },

    { 
        featureType: "road.local", 
        elementType: "geometry",
        stylers: [
        {
            visibility: "simplified"
        },
{
            saturation: -100
        },
{
            hue: "#00fff7"
        },
{
            lightness: -10
        }
        ]
        },

        { 
        featureType: "road.local", 
        elementType: "labels",
        stylers: [ 
        {
            visibility: "off"
        }
                            
        ]
    },
{
        featureType: "road.highway",
        elementType: "geometry",
        stylers: [
        {
            visibility: "simplified"
        },
{
            saturation: -100
        },
{
            hue: "#ffcc00"
        },
{
            lightness: -40
        },
{
            invert_ligthness: true
        }
        ]
    },
    {
        featureType: "road.highway",
        elementType: "labels",
        stylers: [
        {
            visibility: "simplified"
        },
{
            saturation: 70
        },
{
            hue: "#ff0e00"
        },
{
            lightness: 0
        }
        ]
    },
    {
        featureType: "transit",
        stylers: [
        {
            visibility: "off"
        }
        ]
    },
    {
        featureType: "poi.place_of_worship",
        elementType: "labels",
        stylers: [
        {
            visibility: "off"
        }
        ]
    }
    ] // End of style array




themes['gmapFreshStyle'] = [
                    
                    //////////
                    // WATER
                    //////////
                    {
                        featureType: "water",
                        stylers: [
                            {hue: "#0096ff"},
                            {saturation: 39},
                            {lightness: -8}
                        ]
                    },
                    
                    //////////
                    // General Landscape
                    //////////
                    {
                        featureType: "landscape.man_made", // Set the ground color in cities
                        elementType: "geometry",
                        stylers: [
                            {visibility: "on"},
                            {hue: "#ff8000"},
                            {saturation: 2},
                            {lightness: -4}
                        ]
                    },
                    {
                        featureType: "administrative.land_parcel", // Remove borders between buildings
                        stylers: [
                            {visibility: "off"}
                        ]
                    },
                    {
                        featureType: "administrative.neighborhood", // Remove neighborhood labels
                        stylers: [
                            {visibility: "off"}
                        ]
                    },
                    {
                        featureType: "landscape.man_made",
                        elementType: "labels",
                        stylers: [
                            {visibility: "off"}
                        ]
                    },
                    
                    //////////
                    // Point Of Interest
                    //////////
                    {
                        featureType: "poi.park",
                        stylers: [
                            {hue: "#91ff00"},
                            {saturation: 15},
                            {lightness: 0}
                        ]
                    },
                    {
                        featureType: "poi.business",
                        stylers: [
                            {visibility: "off"}
                        ]
                    },
                    {
                        featureType: "poi.sports_complex", // Remove sport area
                        elementType: "labels",
                        stylers: [
                            {visibility: "off"}
                        ]
                    },
                    {
                        featureType: "poi.government",
                        elementType: "labels",
                        stylers: [
                            {visibility: "off"}
                        ]
                    },
                    {
                        featureType: "poi.medical",
                        elementType: "labels",
                        stylers: [
                            {visibility: "off"}
                        ]
                    },
                   
                    
                    //////////
                    // Roads
                    //////////
                    { 
                        featureType: "road", 
                        elementType: "labels",
                        stylers: [ 
                            {hue: "#000000"},
                            {saturation: -100},
                            {gamma: 2},
                            {lightness: "10"} 
                        ]},
                    
                    {
                        featureType: "road.arterial",
                        elementType: "geometry",
                        stylers: [
                            {visibility: "simplified"},
                            {saturation: 59},
                            {hue: "#00fff7"},
                            {lightness: 87},
                            {gamma: 3.82}
                        ]
                    },

                    { 
                        featureType: "road.local", 
                        elementType: "labels",
                        stylers: [ 
                            {visibility: "off"}
                            
                        ]},
                    {
                        featureType: "road.highway",
                        elementType: "geometry",
                        stylers: [
                            {visibility: "on"},
                            {saturation: 59},
                            {hue: "#00fff7"},
                            {lightness: 87},
                            {gamma: 3.82}
                        ]
                    },
                    {
                        featureType: "transit",
                        stylers: [
                            {visibility: "off"}
                        ]
                    },
                    {
                        featureType: "poi.place_of_worship",
                        elementType: "labels",
                        stylers: [
                            {visibility: "off"}
                        ]
                    }
                ]; // End of style array
themes['gmapGreyStyle'] = [
                    
//////////
// WATER
//////////
{
    featureType: "water",
    stylers: [
    {
        hue: "#ff0000"
    },
    {
        saturation: -100
    },
    {
        lightness: 20
    }
    ]
},
                    
//////////
// General Landscape
//////////
{
    featureType: "landscape.man_made", // Set the ground color in cities
    elementType: "geometry",
    stylers: [
    {
        visibility: "on"
    },
    {
        hue: "#ff0000"
    },
    {
        saturation: -100
    },
    {
        lightness: 1
    }
    ]
},
{
    featureType: "landscape.natural",
    elementType: "geometry",
    stylers: [
    {
        visibility: "on"
    },
    {
        hue: "#ff0000"
    },
    {
        saturation: -100
    },
    {lightness: -1}
    ]
},
{
    featureType: "administrative", // Remove neighborhood labels
    elementType: "labels",
     stylers: [
    {hue: "#ff0000"},
    {saturation: -100},
    {lightness: 30}
    ]
},
{
    featureType: "administrative.land_parcel", // Remove borders between buildings
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "administrative.neighborhood", // Remove neighborhood labels
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "landscape.man_made",
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
                    
//////////
// Point Of Interest
//////////
{
    featureType: "poi",
    elementType: "geometry",
    stylers: [
    {
        hue: "#ff0000"
    },
    {
        saturation: -100
    },
    {
        lightness: 70
    }
    ]
},
                    
{
    featureType: "poi",
    elementType: "labels",
    stylers: [
                            
    {
        saturation: -100
    },
    {
        lightness: 20
    }
    ]
},
{
    featureType: "poi.business",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "poi.sports_complex", // Remove sport area
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "poi.government",
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "poi.medical",
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
                   
                    
//////////
// Roads
//////////
{ 
    featureType: "road", 
    elementType: "labels",
    stylers: [
    { saturation: -100 },
    { hue: "#00fff7"},
    { lightness: 40}
    ]
},
                    
{
    featureType: "road.arterial",
    elementType: "geometry",
    stylers: [
    { visibility: "simplified" },
    { saturation: -100 },
    { hue: "#00fff7"},
    { lightness: 10}
    ]
},

{ 
    featureType: "road.local", 
    elementType: "geometry",
    stylers: [ 
    {
        visibility: "simpliefied"
    }
                            
    ]
},
{ 
    featureType: "road.local", 
    elementType: "labels",
    stylers: [ 
    {
        visibility: "off"
    }
                            
    ]
},
{
    featureType: "road.highway",
    elementType: "geometry",
    stylers: [
    { visibility: "simplified" },
    { saturation: -100 },
    { hue: "#00fff7"},
    { lightness: 40}
    ]
},
{
    featureType: "transit",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "poi.place_of_worship",
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
}
] // End of style array

   themes['gmapNightStyle'] = [
                    
                    //////////
                    // ALL
                    //////////
                    {
                        stylers: [
                            { hue: "#00b1ff" },
                            {invert_lightness: true}
                            
                        ]
                    },
                    
                    //////////
                    // WATER
                    //////////
                    {
                        featureType: "water",
                        stylers: [
                            { hue: "#009aff" },
                            { saturation: 75 },
                            { lightness: -64 }
                        ]
                    },
                                     
                    //////////
                    // General Landscape
                    //////////
                    
                    {
                        featureType: "administrative", // Borders color
                        elementType: "geometry",
                        stylers: [
                            { visibility: "off" }
                        ]
                    }, 
                     {
                        featureType: "administrative", // Remove borders between buildings
                        elementType: "labels",
                        stylers: [
                            
                            { hue: "#00bfff" },
                            { saturation: 38 },
                            { lightness: -50 }
                        ]
                    },
                    {
                        featureType: "administrative.province", // Remove all labels about countris, provinces, cities, ...
                        elementType: "labels",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },                    
                    {
                        featureType: "landscape.man_made", 
                       stylers: [
                            
                            { hue: "#00bfff" },
                            { saturation: 48 },
                            { lightness: -5  }
                        ]
                    },
                    {
                        featureType: "landscape.natural",
                        stylers: [
                            
                            { hue: "#00bfff" },
                            { saturation: 48 },
                            { lightness: 5  }
                        ]
                    },
                    {
                        featureType: "administrative.land_parcel", // Remove borders between buildings
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "administrative.neighborhood", // Remove neighborhood labels
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "landscape.man_made",
                        elementType: "labels",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    
                    //////////
                    // Point Of Interest
                    //////////
         
                    {
                        featureType: "poi",
                        elementType: "geometry",
                        stylers: [
                            { hue: "#00bfff" },
                            { saturation: 18 },
                            { lightness: -99  },
                            {gamma : 4}
                        ]
                    },
                    {
                        featureType: "poi.medical",
                        elementType: "geometry",
                        stylers: [
                            { visibility: "on" },
                            { lightness: -10  }
                        ]
                    },
                    {
                        featureType: "poi.government",
                        elementType: "geometry",
                        stylers: [
                            { hue: "#00bfff" },
                            { saturation: 28 },
                            { lightness: 4  }
                        ]
                    },
                    {
                        featureType: "poi.attraction",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "poi.business",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "poi.government",
                        elementType: "labels",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "poi.government",
                        elementType: "geometry",
                        stylers: [
                            { hue: "#00bfff" },
                            { saturation: 28 },
                            { lightness: -30  }
                        ]
                    },
                    {
                        featureType: "poi.park",
                        elementType: "labels",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "poi.park",
                        elementType: "geometry",
                        stylers: [
                            { hue: "#00bfff" },
                            { saturation: 28 },
                            { lightness: -30  }
                        ]
                    },
                    {
                        featureType: "poi.place_of_worship",
                        elementType: "labels",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "poi.school",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "poi.sports_complex",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    
                   
                    //////////
                    // Roads
                    //////////

                    {
                        featureType: "road.local",
                        elementType: "labels",
                        stylers: [
                            
                            { hue: "#00bfff" },
                            { saturation: 48 },
                            { lightness: -60  }
                        ]
                    },
                    {
                        featureType: "road.local",
                        elementType: "geometry",
                        stylers: [
                            {visibility:"simplified"}
                        ]
                    },
                   
                    {
                        featureType: "road.arterial",
                        elementType: "labels",
                        stylers: [
                            
                            { hue: "#00bfff" },
                            { saturation: 28 },
                            { lightness: -60  }
                        ]
                    },
                    {
                        featureType: "road.arterial",
                        elementType: "geometry",
                        stylers: [
                            { visibility: "simplified" },
                            { hue: "#00bfff" },
                            { saturation: 28 },
                            { lightness: -70  }
                        ]
                    },
                   
                    {
                        featureType: "road.highway", // slim highways
                        elementType: "geometry",
                        stylers: [
                            { visibility: "simplified" },
                            { hue: "#00bfff" },
                            { saturation: 38 },
                            { lightness: -60  }
                        ]
                    },
                    
                    {
                        featureType: "road.highway",
                        elementType: "labels",
                        stylers: [
                            { hue: "#00bfff" },
                            { saturation: 28 },
                            { lightness: -70  }
                            
                        ]
                    },
                    
                    {
                        featureType: "transit",
                        elementType: "geometry",
                        stylers: [
                            { visibility: "off" }
                        ]
                    },
                    {
                        featureType: "transit",
                        elementType: "labels",
                        stylers: [
                            { visibility: "simplified" },
                            { hue: "#00bfff" },
                            { saturation: 18 },
                            { lightness: -50 }
                        ]
                    }
                    
                ]; // End of style array
                themes['gmapOldStyle'] = [
                    
//////////
// WATER
//////////
{
    featureType: "water",
    stylers: [
    {
        hue: "#00ffe0"
    },
    {
        saturation: -60
    },
    {
        lightness: 0
    }
    ]
},
                    
//////////
// General Landscape
//////////
{
    featureType: "landscape.man_made", // Set the ground color in cities
    elementType: "geometry",
    stylers: [
    {
        visibility: "on"
    },
    {
        hue: "#ffbf00"
    },
    {
        saturation: -25
    },
    {
        lightness: 40
    }
    ]
},
{
    featureType: "landscape.natural", // Set the ground color in cities
    elementType: "geometry",
    stylers: [
    {
        hue: "#bdff00"
    },
    {
        saturation: -35
    },
    {
        lightness: 20
    }
    ]
},
{
    featureType: "administrative", // Remove borders between buildings
    elementType: "labels",
    stylers: [
    {
        saturation: -90
    },
    {
        lightness: 30
    }
    ]
},
{
    featureType: "administrative.land_parcel", // Remove borders between buildings
    stylers: [
    {
        visibility: "on"
    }
    ]
},
{
    featureType: "administrative.neighborhood", // Remove neighborhood labels
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "landscape.man_made",
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
                    
//////////
// Point Of Interest
//////////
{
    featureType: "poi", // Remove borders between buildings
    elementType: "labels",
    stylers: [
    {
        saturation: -90
    },
    {
        lightness: 30
    }
    ]
},
{
    featureType: "poi.park",
    stylers: [
    {
        hue: "#bdff00"
    },
    {
        saturation: -35
    },
    {
        lightness: 3
    }
    ]
},
{
    featureType: "poi.business",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "poi.sports_complex", // Remove sport area
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "poi.government",
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "poi.medical",
                        
    stylers: [
                            
    {
        visibility: "on"
    },
    {
        hue: "#ff1b00"
    },
    {
        saturation: -10
    },
    {
        lightness: 10
    }
    ]
},
{
    featureType: "poi.school",
                        
    stylers: [
    {
        visibility: "on"
    },
    {
        hue: "#ffbe00"
    },
    {
        saturation: -10
    },
    {
        lightness: 0
    }
    ]
},
                    
                   
                    
//////////
// Roads
//////////
{ 
    featureType: "road", 
    elementType: "labels",
    stylers: [ 
    {
        hue: "#000000"
    },
    {
        saturation: -100
    },
    {
        gamma: 2
    },
    {
        visibility: "on"
    } 
    ]
},
                    
{
    featureType: "road.arterial",
    elementType: "geometry",
    stylers: [
    {
        visibility: "simplified"
    },
    {
        saturation: -100
    },
    {
        hue: "#00fff7"
    },
    {
        lightness: 20
    }
    ]
},
{
    featureType: "road.arterial",
    elementType: "labels",
    stylers: [
    {
        visibility: "on"
    },
    {
        saturation: -100
    },
    {
        hue: "#00fff7"
    },
    {
        lightness: 20
    }
    ]
},

{ 
    featureType: "road.local", 
    elementType: "geometry",
    stylers: [
    {
        visibility: "simplified"
    },
    {
        saturation: -100
    },
    {
        hue: "#00fff7"
    },
    {
        lightness: -10
    }
    ]
},

{ 
    featureType: "road.local", 
    elementType: "labels",
    stylers: [ 
    {
        visibility: "off"
    }
                            
    ]
},
{
    featureType: "road.highway",
    elementType: "geometry",
    stylers: [
    {
        visibility: "simplified"
    },
    {
        saturation: -90
    },
    {
        hue: "#ffcc00"
    },
    {
        lightness: 5
    }
    ]
},
{
    featureType: "road.highway",
    elementType: "labels",
    stylers: [
    {
        visibility: "simplified"
    },
    {
        saturation: 30
    },
    {
        hue: "#ff0e00"
    },
    {
        lightness: 0
    }
    ]
},
{
    featureType: "transit",
    stylers: [
    {
        visibility: "off"
    }
    ]
},
{
    featureType: "poi.place_of_worship",
    elementType: "labels",
    stylers: [
    {
        visibility: "off"
    }
    ]
}
]; // End of style array


themes['gMapNeutralBlue'] = [{"featureType":"water","elementType":"geometry","stylers":[{"color":"#193341"}]},{"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#2c5a71"}]},{"featureType":"road","elementType":"geometry","stylers":[{"color":"#29768a"},{"lightness":-37}]},{"featureType":"poi","elementType":"geometry","stylers":[{"color":"#406d80"}]},{"featureType":"transit","elementType":"geometry","stylers":[{"color":"#406d80"}]},{"elementType":"labels.text.stroke","stylers":[{"visibility":"on"},{"color":"#3e606f"},{"weight":2},{"gamma":0.84}]},{"elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},{"featureType":"administrative","elementType":"geometry","stylers":[{"weight":0.6},{"color":"#1a3541"}]},{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},{"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#2c5a71"}]}]
themes['gMapCobalt'] = [{"featureType":"all","elementType":"all","stylers":[{"invert_lightness":true},{"saturation":10},{"lightness":30},{"gamma":0.5},{"hue":"#435158"}]}]
themes['gMapRetro'] = [
   {
      "featureType":"administrative",
   },
   {
      "featureType":"poi",
      "stylers":[
         {
            "visibility":"simplified"
         }
      ]
   },
   {
      "featureType":"road",
      "elementType":"labels",
      "stylers":[
         {
            "visibility":"simplified"
         }
      ]
   },
   {
      "featureType":"water",
      "stylers":[
         {
            "visibility":"simplified"
         }
      ]
   },
   {
      "featureType":"transit",
      "stylers":[
         {
            "visibility":"simplified"
         }
      ]
   },
   {
      "featureType":"landscape",
      "stylers":[
         {
            "visibility":"simplified"
         }
      ]
   },
   {
      "featureType":"road.highway",
      "stylers":[
         {
            "visibility":"off"
         }
      ]
   },
   {
      "featureType":"road.local",
      "stylers":[
         {
            "visibility":"on"
         }
      ]
   },
   {
      "featureType":"road.highway",
      "elementType":"geometry",
      "stylers":[
         {
            "visibility":"on"
         }
      ]
   },
   {
      "featureType":"water",
      "stylers":[
         {
            "color":"#84afa3"
         },
         {
            "lightness":52
         }
      ]
   },
   {
      "stylers":[
         {
            "saturation":-17
         },
         {
            "gamma":0.36
         }
      ]
   },
   {
      "featureType":"transit.line",
      "elementType":"geometry",
      "stylers":[
         {
            "color":"#3f518c"
         }
      ]
   }
]