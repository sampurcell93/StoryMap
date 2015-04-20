define "router", ["hub", "queries", "loaders", "stories", "timeline", "user", "map"], (hub, queries, loaders, stories, timeline, user, map) ->

    dispatcher = hub.dispatcher;

    _activeFeeds = user.getActiveUser().getActiveFeeds()
    loaders = new loaders()

    class ProgressBarUpdater
        constructor: ->
            @finishedRetrievingCount = 0
            @finishedAnalysisCount = 0
            @totalStoriesBeingAnalyzed = 0
            @currentProgressBarVal = .1
            @progressBar = loaders.get("generic");
            @progressBar.el = $("#overall-progress")
            @progressBar.number = $("#overall-progress-number")
            @hideBar()
            _.extend @, Backbone.Events
        hideBar: ->
            @progressBar.hide()
        showBar: ->
            @progressBar.show()
        _done: ->
            @stopListening @collection
            @hideBar()
            dispatcher.dispatch("render:timeline");
            @done.call(@);
        done: ->
        listenToAnalysisProgress: ->
            if !@collection?
                console.error("ProgressBarUpdater needs a collection to listen to.")
                return @
            @listenTo @collection, "done:analysis", =>
                @finishedAnalysisCount++
                newVal = @currentProgressBarVal + ((@finishedAnalysisCount / @totalStoriesBeingAnalyzed) * 100)
                @progressBar.set(newVal);
                console.log(newVal)
                if newVal >= 95 then @_done()
            @
        listenToRetrievalProgress: (retrievalObj, feed, len, next=null, first=false) ->
            if first is true and !@progressBar.finalStage
                @progressBar.setText("Getting news stories from #{feed}...");
            @listenToOnce retrievalObj, "retrieval_#{feed}:done", =>
                @progressBar.setText("Done getting stories from #{feed}...");
                setTimeout =>
                    if next?
                        @progressBar.setText("Getting news stories from #{next}...")
                    else
                        @progressBar.finalStage = true
                        @progressBar.setText("Analyzing news stories for location...")
                        dispatcher.dispatch("analyze", feed);
                        activeStories = stories.getActiveSet();
                        activeStories.analyze();
                , 1000
                @totalStoriesBeingAnalyzed += retrievalObj.totalStoriesRetrieved[feed]?.retrieved || 0
                @finishedRetrievingCount++
                # Multiply by .1 to reflect the relative insignificance 
                # of retrieval as compared to analysis and parsing
                @progressBar.set((@finishedRetrievingCount/len*100)*.2)
        destroy: -> 
            @stopListening()



    class Controller extends Marionette.Controller
        registerListeners: (from) ->
            # Should be a listenTo, need to debug why not working
            from.on "execute:query", @executeQuery
            @progressUpdater = new ProgressBarUpdater()
            @progressUpdater.done = ->
                dispatcher.dispatch "destroy:timeline"
                tl = new timeline.TimelineView({collection: @collection, map: map.getActiveMap().map});
                tl.reset().updateHandles(true).render()
                @trigger "done"

        executeQuery: (query, exists) => 
            if exists is true
                @router.navigate("existing/#{query}", true);
            else 
                @router.navigate("fetch/#{query}", true);
        renderExistingQueries: (queries) ->
            @renderExistingQuery queries
            # queries = queries.split("/");
            # _.each queries, (query, i) =>
                # if ()
        renderExistingQuery: (query) ->
            request = queries.createRequest(query);
            promise = request.fetchExistingQuery()

            promise.success (response) =>
                @progressUpdater.hideBar()
                dispatcher.dispatch "render:topbar", query
                query = queries.setActiveQuery(response);
                dispatcher.dispatch "add:map", query
                dispatcher.dispatch "render:timeline"
                dispatcher.dispatch "show:sidebars"
                dispatcher.dispatch "clear:map"
                stories.setActiveStories(query.get("stories"));
                destroyActiveModal()
            .error ->
                console.log "error fetching existing"
        fetchNewQuery: (query) ->
            @progressUpdater.destroy()
            @progressUpdater = new ProgressBarUpdater(query)
            @progressUpdater.showBar()
            activeStorySet = new stories.Stories();
            q = queries.setActiveQuery({
                title: query,
                stories: activeStorySet
            })
            dispatcher.dispatch "add:map", q
            dispatcher.dispatch "show:sidebars"
            dispatcher.dispatch "clear:map"
            stories.setActiveStories(activeStorySet);
            @progressUpdater.collection = activeStorySet
            @progressUpdater.listenToAnalysisProgress()
            request = queries.createRequest(query, activeStorySet);
            # Even if a fetch URL is specified, check to make sure the query does not already exist.
            request.doesExist (response) =>
                if response.exists is true
                    @router.navigate("existing/#{query}", true)
                else
                    retrievalObj = request.totalStoriesRetrieved
                    _.each _activeFeeds, (feed, i) =>
                        setTimeout =>
                            next = _activeFeeds[i+1]
                            first = if i is 0 then true else false
                            @progressUpdater.listenToRetrievalProgress(retrievalObj, feed, _activeFeeds.length, next, first)
                            request.getNews(feed)
                        , 300*i
                    dispatcher.dispatch "render:topbar", query
                    destroyActiveModal()


    class Router extends Marionette.AppRouter   
        initialize: ->
            @controller = new Controller
            @controller.router = @
            @controller.registerListeners(hub.dispatcher);
            hub.dispatcher.on "navigate", (route, opts) =>
                @navigate(route, opts);
        appRoutes: {
            "existing/*splat": "renderExistingQueries"
            "fetch/:query": "fetchNewQuery"
        }

    Router