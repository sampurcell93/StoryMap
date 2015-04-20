define "coreUI", ["hub", "typeahead", "loaders", "modals", "queries", "stories", "map", "user", "sweetalert", "timeline"], (hub, typeahead, loaders, Modal, queries, stories, maps, user, sweet,  timeline) ->
    lFactory = new loaders();
    dispatcher = hub.dispatcher;


    class EntryWayView extends Backbone.View
        el: "#entryway-view"
        toggleViewState: ->
            if @isModal is true
                @morphToTopBar()
            else 
                @morphToModal()
        initialize: ->
            @queryInput = @$('#js-make-query')
            @saveButton = @$("#save-active-query");
            @bindTypeahead()
            @isModal = true
            @listenTo dispatcher, "render:topbar", (query) =>
                @morphToTopBar()
                if query?
                    @queryInput.typeahead('val', query)
                @queryInput.blur()
                @checkCurrentQueryState();
        checkCurrentQueryState: ->
            request = queries.createRequest(@autoComplete.getCurrentInput());
            request.doesExist (response) =>
                if response.exists is true
                    @saveButton.hide()
        morphToModal: ->
            @isModal = true;
            @$el.removeClass("top-bar")
        morphToTopBar: (query) ->
            return @ if @isModal is false
            @isModal = false;
            @$el.addClass("top-bar");
            @saveButton.fadeIn("fast").attr("disabled", false);
            toggleSideBar("show");
            @
        hideSaveButton: ->
            @saveButton.fadeOut("fast").attr("disabled", true);
            @
        bindTypeahead: ->
            @autoComplete = new queries.QueryAutoComplete(@$("#js-make-query"))
        showSaved: ->
            m = new Modal({content: [queries.getHelpString(), queries.getSavedQueriesList()]});
            m.launch();
        showPreferences: ->
            m = new Modal({content: user.getPreferencesView({model: user.getActiveUser()}).el})
            m.launch()
        showHelp: ->
            m = new Modal({content: _.template($("#help-template").html())()});
            m.launch()
            m.$el.css("top", 320 + "px")
        saveSuccess: (title) ->
            dispatcher.dispatch("navigate", "existing/#{title}", {replace: true, trigger: false})
            swal({
                title: "Saved!",  
                text: "You saved this query! You can look at it any time, and we'll be updating it in the background.",  
                allowOutsideClick: true
                type: "success",   
                confirmButtonText: "OK" 
                timer: 4500
            });
        events: 
            "click .js-saved": "showSaved"
            "click .js-preferences": "showPreferences"
            "click .js-help": "showHelp"
            "click #search-new-query": (e) ->
                request = queries.createRequest(@autoComplete.getCurrentInput());
                request.doesExist (response) =>
                    if response.exists is false
                        @autoComplete.query(true);
                        @saveButton.show()

            "click #save-active-query": (e) ->
                $t = $(e.currentTarget);
                saveSuccess = @saveSuccess
                spinner = $(lFactory.get("spinner"))
                $t = $ e.currentTarget;
                query = queries.getActiveQuery();
                $t.append(spinner);
                request = queries.createRequest(query.get("title"));
                # Check if the query exists - if it does, merely "favorite" it
                request.doesExist (response) =>
                    # Link the user to the query
                    query?.favorite().success =>
                        if (response.exists is false)
                            # Save each story to the DB
                            allStories = query.get("stories")
                            allStories.create().success -> 
                                saveSuccess(query.get "title")
                                spinner.remove()
                                $t.hide()
                        else 
                            saveSuccess(query.get "title")
                            spinner.remove()
                            $t.show();


    entryWay = null;

    toggleSidebarAnimation = (count, map) ->
        if map?
            google.maps.event.trigger map, 'resize'
            map.setZoom map.getZoom()
            frame = requestAnimationFrame ->
                toggleSidebarAnimation ++count, map

        if count > 100 or !map?
            cancelAnimationFrame(frame)
        

    toggleSideBar = (dir) ->
        $fullSize = $(".shift-to-full, .top-bar, .all-stories")
        if dir is "show"
            $fullSize.removeClass "away fullsize"
        else if dir is "hide"
            $fullSize.addClass "away fullsize"
        else
            $fullSize.toggleClass("away").toggleClass "fullsize"

        map = maps.getActiveMap()?.map;
        toggleSidebarAnimation 0, map

    return {
        load: ->
            entryWay = new EntryWayView()
            timelineFactory = timeline.TimelineFactory();
            twoDatePickerFactory = timeline.TwoDatePickerFactory()
            timeline = null;
            twoDatePicker = null;

            $(".js-toggle-view").click -> toggleSideBar()

            ###################################
            #### Global messenger listeners ###
            ###################################

            dispatcher.on "show:sidebars", -> 
                toggleSideBar("show");
                # if tl?
                    # tl.$el.slideDown("fast");



            dispatcher.on "add:feedLoader", (name, loadingRequest) ->
                # l = lFactory.get("feedAnalysis", name)
                if loadingRequest?
                    # l.listener.monitorChanges loadingRequest, name
                    activeStories = stories.getActiveSet() ;
                    group = activeStories.getGroup(name);
                    loadingRequest.on "retrieval_#{name}:done", => group.analyze()
                # l.listener.render()

            dispatcher.on "execute:query", (q) ->
                entryWay.morphToTopBar();

            dispatcher.on "destroy:timeline", (query) ->
                if timeline
                    timeline.destroy()


            dispatcher.on "show:timeline", (query) ->
                if timeline
                    timeline.show()

            dispatcher.on "add:map", (query) ->
                if timeline
                    timeline.destroy()
                timeline = timelineFactory();
                dateRange = timeline.dateRange;
                timeline.setCollection(query.get("stories"));
                dateRange.setCollection(query.get("stories"));
                twoDatePicker = twoDatePickerFactory({
                    dateRange: dateRange,
                    startElement: document.getElementById("start-date-picker")
                    endElement: document.getElementById("end-date-picker")
                })
                timeline.show()
                # tl.hide().reset().updateHandles().render()

             $(".js-filter-stories").keyup (e) ->
                val = $(@).val()
                key = e.keyCode or e.which
                activeStories = stories.getActiveSet()
                if activeStories? and key isnt 32
                    filterer = new stories.StoryFilter(activeStories)
                    filterer.filter(val);

            # Bind dropdown event handler for responsive design
            $("nav").on "click", ->
                if $(window).width() < 1184
                    $(@).toggleClass("showing-menu");

    }


