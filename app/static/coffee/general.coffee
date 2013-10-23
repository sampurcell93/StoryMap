$ ->

    # Quick logging
    window.cc = (arg) ->
        console.log arg

    Number.prototype.monthToString = ->
        months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December']
        months[@valueOf()] || "Invalid"

    Number.prototype.dayToString = ->
        days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        days[@valueOf()] || "Invalid"

    Date.prototype.cleanFormat = ->
       @getDate() + "/" + parseInt(@getMonth() + 1) + "/" + @getFullYear()

    $(@).on "click switch", "[data-switch-icon]", ->
        $t = $ this
        switchicon = $t.data("switch-icon")
        curricon = $t.attr("class").split(" ")
        _.each curricon, (classname) ->
            if classname.indexOf("icon") > -1
                curricon = classname
                false
        $t.removeClass curricon
        $t.addClass(switchicon)
        $t.data("switch-icon", curricon)

    # launch modals
    # args: content for the modal, as an array of content
    # rets the modal jquery obj
    window.launchModal =  (content, options) ->
        destroyModal true
        defaults = 
            close: true
            destroyHash: false
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
                if options.destroyHash is true
                    window.location.hash = ""
        $(document.body).addClass("active-modal").append(modal)
        modal
    window.destroyModal = (existing) ->
        $(".modal").fadeOut "fast", ->
            unless existing == true
                $(document.body).removeClass("active-modal")