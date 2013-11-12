$ ->

    window.models = {}
    window.collections = {}

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


    String.prototype.stripHTML = ->
        div = document.createElement("div")
        div.innerHTML = @
        div.innerText

    $(@).on "click switch", "[data-switch-icon]", ->
        $t = $ this
        switchicon = $t.data("switch-icon")
        curricon = $t.attr("class").split(" ")
        $.each curricon, (index, classname) ->
            if classname.indexOf("icon") > -1
                curricon = classname
                false
        $t.removeClass curricon
        $t.addClass(switchicon)
        $t.data("switch-icon", curricon)

    # launch modals - dependent on jquery for arrays
    # args: content for the modal, as an array of content
    # rets the modal jquery obj
    window.launchModal =  (content, options) ->
        destroyModal true
        defaults = 
            close: true
            destroyHash: false
        options = $.extend defaults, options
        modal = $("<div />").addClass("modal")
        try
            if $.isArray(content)
              $.each content, (index, item) ->
                  modal.append(item)
            else modal.html(content)
        unless options.close is false
            modal.prepend("<i class='close-modal icon-uni67'></i>")
            modal.find(".close-modal").on "click", ->
                destroyModal(null, options)
        $(document.body).addClass("active-modal").append(modal)
        modal
    window.destroyModal = (existing, options) ->
        options = $.extend {destroyHash: true}, options
        $(".modal").fadeOut "fast", ->
            unless existing == true
                $(document.body).removeClass("active-modal")
                if options.destroyHash == true
                    window.location.hash = ""
