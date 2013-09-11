$ ->
  window.launchModal =  (content) ->
    modal = $("<div />").addClass("modal")
    if $.isArray(content)
        _.each content, (item) ->
            modal.append(item)
    else modal.html(content)
    modal.prepend("<i class='close-modal icon-untitled-7'></i>")
    $(document.body).addClass("active-modal").append(modal)
    modal

  # cache the search bar
  $search = $("#news-search")
  # cache go button
  $go = $("#go")

  $search.focus().on "keydown", (e) ->
    if e.keyCode is 13 or e.which is 13
      $go.trigger "click"
      return
    $(this).data "start_index", $(this).data("start_index") + 1

  # $("#date-slider").slider()

  $go.on "click", ->
    StoryMap = window.StoryMap
    StoryMap.numStories = 0
    for m of StoryMap.markers
      StoryMap.markers[m].setMap null
    for i in [StoryMap.numStories..StoryMap.numStories + 12] by 4
      getGoogleNews $search.val(), i

