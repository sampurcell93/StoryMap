$ ->
    Number.prototype.monthToString = ->
        months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December']
        months[@valueOf()] || "Not a valid month"
    Number.prototype.dayToString = ->
        days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        days[@valueOf() || "Not a valid day"]

    Date.prototype.cleanFormat = ->
       @getDate() + "/" + @getMonth() + "/" + @getFullYear()