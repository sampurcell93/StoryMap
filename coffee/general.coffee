$ ->

    Number.prototype.monthToString = ->
        months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December']
        months[@valueOf()] || "Invalid"

    Number.prototype.dayToString = ->
        days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        days[@valueOf()] || "Invalid"

    Date.prototype.cleanFormat = ->
       @getDate() + "/" + parseInt(@getMonth() + 1) + "/" + @getFullYear()

    # launch modals
    # args: content for the modal, as an array of content
    # rets the modal jquery obj
    window.launchModal =  (content, options) ->
        defaults = 
            close: true
        options = _.extend defaults, options
        modal = $("<div />").addClass("modal")
        if $.isArray(content)
          _.each content, (item) ->
              modal.append(item)
        else modal.html(content)

        unless options.close is false
            modal.prepend("<i class='close-modal icon-untitled-7'></i>")
            modal.find(".close-modal").on "click", ->
                $(document.body).removeClass("active-modal")
                modal.remove()
        $(document.body).addClass("active-modal").append(modal)
        modal
    window.destroyModal = () ->
        $(".modal").fadeOut "fast", ->
            $(document.body).removeClass("active-modal")
