$ ->
    $(".js-register").on "click", ->
        launchModal($(".js-register-panel").html(), { destroyHash: true})
    $(@).delegate ".js-register-submit" ,"click", (e) ->
        $t = $ @
        form = $t.closest "form"
        name = (attr) ->
            "[name=" + attr + "]"
        pass = form.find(name("password")).val()
        confirm = form.find(name("confirm-password")).val()
        if pass != confirm
            alert("Your passwords don't match")
            e.preventDefault()
            return false
        empty = false
        form.find("input").each( ->
            if $(@).val() == ""
                empty = true
        )
        if empty then e.preventDefault()
        true

