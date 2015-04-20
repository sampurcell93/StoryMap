define "stories", ["hub", "modals"], (hub, Modal) ->

    _activeStories = null;
    dispatcher = hub.dispatcher;

    stripHTML = ->
        div = document.createElement("div")
        div.innerHTML = @
        div.innerText

    class Story extends Backbone.Model
        url: ->
            url = "./stories"
            if @id then url += "/" + @id
            url
        defaults: ->
            return {
                url: "#"
            }
        parse: (response) ->
            response.date = moment(response.date);
            response.created = moment(response.created);
            response
        hasCoordinates: -> @get("lat")? and @get("lng")?

    class GeoCoder
        constructor: (@address) ->
        geocodeUrl: 'http://maps.googleapis.com/maps/api/geocode/json?sensor=true&address='
        geocode: -> $.getJSON @geocodeUrl + encodeURIComponent(@address)


    class GeoListItem extends Marionette.ItemView
        tagName: 'li'
        template: "#geocode-choice"
        chooseLocation: ->
            targetStory = @model.collection.story
            targetStory.save {
                lat: @model.get("geometry").location.lat
                lng: @model.get("geometry").location.lng
                location: @model.get("formatted_address")
            }, {
                success: => 
                    targetStory.trigger("find", targetStory);
                    window.destroyActiveModal();
                    dispatcher.dispatch("plot:story", targetStory)
                error:   => console.log arguments
            }
        events: 
            "click": "chooseLocation"

    class GeoList extends Marionette.CollectionView
        childView: GeoListItem

    class GeoCoderView extends Backbone.View
        enterLocTemplate: _.template($("#enter-loc").html() || "")
        render: ->
            @$el.html(@enterLocTemplate(@model.toJSON()));
            @
        fetchLocations: (address) ->
            geocoder = new GeoCoder(address);
            geocoder.geocode().success (response) =>
                collection = new Backbone.Collection(response.results);
                collection.story = @model;
                new GeoList({
                    el: @$(".geocode-choices"),
                    model: @model,
                    collection: collection
                }).render();
            .error ->
        events:
            "click .js-geocode-go": ->
                input = @$(".js-address-value").val()
                if input then @fetchLocations(input)
            "keydown .js-address-value": (e) ->
                $t = $ e.currentTarget
                if $t.val() and e.keyCode is 13 then @fetchLocations($t.val());


    class StoryFilter
        constructor: (@collection) ->
        filterFns:  
            "location":(story) ->  story.get("lat") != null and story.get("lng") != null
            "nolocation":(story) -> story.get("lat") == null and story.get("lng") == null
            "favorite":(story) -> false
            "google":(story) -> story.get("aggregator") == "google"
            "yahoo":(story) -> story.get("aggregator") == "yahoo"
        filter: (val) ->
            val = val.toLowerCase().replace(" ", "");
            if @collection?
                @collection.each (story) ->
                    title = story.get("title")?.toLowerCase().replace(" ", "")
                    if title.indexOf(val) is -1
                        story.trigger("hide")
                    else 
                        story.trigger("show")


    class StoryAnalyzer
        constructor: ->
            @groups = {}
        analyze: (stories) ->
            console.log(JSON.stringify(stories));
            $.ajax({
              url: './analyze/many',
              type: 'POST',
              data: {"stories": JSON.stringify(stories)}
              dataType: 'json'
            })
            .done((resp) ->
                _.each resp, (r, i) ->
                    story = stories.at(i);
                    _.extend story.attributes, _.omit(r, "title")
                    if (r.lat? and r.lng?)
                        story.trigger("find", story, story.get("lat"), story.get("lng"))
                    story.trigger("done:analysis", story);
            )
            .fail( ->
                console.log("error", arguments);
            )
            .always(->
                console.log("complete", arguments);
            )

    class Stories extends Backbone.Collection
        model: Story
        url: "./stories/many"
        analysisLen: 4
        initialize: ->
            @analyzer = new StoryAnalyzer();

        analyzeGroup: (group=@, startIndex=0, endIndex=@analysisLen) ->
            group = group.slice(startIndex, endIndex)
            if group.length is 0 then return
            setTimeout =>
                @analyzeGroup @, endIndex, endIndex + @analysisLen
            , 1000
            @analyzer.analyze new Stories(group)

        analyze: (group=@, startIndex=0, endIndex=@analysisLen) -> @analyzeGroup();
        getGroup: (group) ->
            if !@analyzer.groups[group]
                @analyzer.groups[group] = new Stories()
            @analyzer.groups[group]
        addToGroup: (group, id) ->
            if !@analyzer.groups[group]
                @analyzer.groups[group] = new Stories()
            @analyzer.groups[group].add(@._byId[id]);
        create: ->
            @each (story) =>
                story.set("query_id", @query.id || @query.get("id"));
            Backbone.sync "create", @, {
                success: -> 
                error: ->   
            }

    class QuickStory extends Backbone.View
        template: _.template($("#quick-story-popup").html() || "")
        className: 'quick-story'
        tagName: 'dl'
        render: ->
          @$el.html(@template(@model.toJSON()))
          @
        events:
          click: ->
            @model.trigger "center"

    # class EmptyStoryItem extends Marionette.ItemView
    #     className: "empty center placeholder"
    #     tagName: 'li'
    #     template: "#empty-story-item"


    class StoryItem extends Marionette.ItemView
        template: "#story-item"
        tagName: 'li'
        initialize: ->
            @popup = new QuickStory({model: @model})
            _.bindAll @, "scrollToThis"
            @listenTo @model, {
                "find": (story) =>    
                   @$el.addClass("has-coordinates");
                "highlight": ->
                    @$el.addClass("highlighted")
                "unhighlight": ->
                    @$el.removeClass("highlighted")
                "hide": ->
                    @$el.hide()
                "show": ->
                    @$el.show()
                "showpopup": @togglePopup
                "change:content": -> alert("changed "); console.log arguments

            }
        launchLocationPicker: ->
            modal = new Modal({content: new GeoCoderView({model: @model}).render().el})
            modal.launch()
        onRender: ->
            if @model.hasCoordinates()
                @$el.addClass("has-coordinates");
        getPosition: ->
            @$el.position().top
        togglePopup: ->
            @popup.render()
            $(".quick-story").not(@popup.el).slideUp "fast"
            if @$(".quick-story").length is 0
                @popup.$el.hide().appendTo(@$el)
            @popup.$el.slideToggle "fast", @scrollToThis
        scrollToThis: ->
            $parent = $("ul.story-list-wrapper");
            pos = @getPosition() + $parent.scrollTop() - 100
            $parent.animate({ scrollTop: pos }, 300);
        events: 
            "click": ->
                do @togglePopup
            "click .js-set-location": (e) ->
                do @launchLocationPicker
                e.stopPropagation()
            "mouseover": ->
                @model.trigger("highlight")
            "mouseout": ->
                @model.trigger("unhighlight")
            "dblclick .article-title":  ->  
              w = window.open(@model.get("url"), "_blank")
              w.focus()



    class StoryList extends Marionette.CollectionView
        el: '.all-stories ul.story-list-wrapper'
        childView: StoryItem
        # emptyView: EmptyStoryItem
        onBeforeRender: ->
            @$el.empty()
        onRender: ->
            @$(".placeholder").remove()
        setCollection: (collection) ->
            if @collection?
                @stopListening @collection
            @collection = collection;
            @bindCollectionListeners()
        bindCollectionListeners: ->
            @listenTo @collection, {
                "add": (story) =>
                    view = new @childView({model: story});
                    @$el.append view.render().el
            }

    _activeStories = new Stories;
    _activeStoryList = new StoryList({collection: _activeStories});
    _activeStoryList.render()
    dispatcher.dispatch("set:activeStories", _activeStories)

    return {
        setActiveStories: (stories) ->
            if stories instanceof Stories
                _activeStories = stories
            else
                _activeStories = new Stories(stories, {parse: true});
            dispatcher.dispatch("set:activeStories", _activeStories)
            _activeStoryList.setCollection(_activeStories);
            _activeStoryList.render()
            _activeStories
        addToActiveSet: (stories) -> 
            if _.isArray(stories)
                _.each stories, (story) ->
                    story = new Story(story, {parse: true});
                    _activeStories.add(story);
                    _activeStories._byId[story.get("title")] = story;
                    _activeStories.addToGroup(story.get("aggregator"), story.get("title"))
            else 
                story = new Story(stories, {parse: true});
                _activeStories.add(story);
                _activeStories._byId[story.get("title")] = story;
                _activeStories.addToGroup(stories.get("aggregator"), stories.get("title"));
        getActiveSet: -> _activeStories
        analyze: (name, notify) -> _activeStories.analyze(name, notify);
        Stories: Stories
        StoryFilter: StoryFilter
    }