$ ->
    Number.prototype.monthToString = ->
        months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December']
        months[@valueOf()] || "Not a valid month"
    Date.prototype.cleanFormat = ->
        @getMonth().monthToString() + " " + @getFullYear()