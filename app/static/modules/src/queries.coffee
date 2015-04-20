define "queries", ["hub", "stories", "map", "typeahead"], (hub, stories, map) ->

    _activeQuery = null;
    _savedQueries = null;
    dispatcher = hub.dispatcher

    # Make _.template typeahead compatible
    ((_) ->
        'use strict';
        _.compile = (templ) ->
            compiled = this.template templ;
            compiled.render = (ctx) ->
                return @(ctx);
            return compiled;
    )(window._);

    searchEngine = new Bloodhound({
        local: window.tokens
        datumTokenizer: (d) ->
            return Bloodhound.tokenizers.whitespace(d.val);
        queryTokenizer: Bloodhound.tokenizers.whitespace
        limit: 30
    });
    searchEngine.initialize()

    class QueryAutoComplete
        constructor: (@el) ->
            $searchbox = @el;
            $searchbox.typeahead(
                {
                    hint: true,
                    minLength: 1,
                    highlight: true
                }, 
                {   
                    source: searchEngine.ttAdapter(),
                    displayKey: "val",
                    templates: {
                        empty: _.compile("<div class='tt-empty-results'>No results found.</div>"),
                        suggestion: _.compile("<%= val %>")
                    }
                }
            ).on("typeahead:selected", (e, suggestion) =>
                dispatcher.dispatch("execute:query", suggestion.val, true);
                e.stopPropagation();
                e.preventDefault();
            );
            @bindEvents();
        bindEvents: ->
            @el.on "keydown", (e) =>
                key = e.keyCode or e.which;
                if key is 13 then @query()
        getCurrentInput: -> @el.typeahead("val") || @el.val();
        query: (force =false) ->
            query = @getCurrentInput();
            request = new QueryRequest(query);
            if force is true 
                dispatcher.dispatch("navigate", "fetch/#{query}", true);
            else
                request.doesExist (response) ->
                    if response.exists is true
                        dispatcher.dispatch("navigate", "existing/#{query}", true);
                    else 
                        dispatcher.dispatch("navigate", "fetch/#{query}", true);

    class StoryRetrievalCounter
        constructor: ->
            @totalStoriesRetrieved = {}
            _.extend @, Backbone.Events
        addToTotal: (feed, incrementValue) ->
            totalStories = @totalStoriesRetrieved[feed]
            if !totalStories
                @totalStoriesRetrieved[feed] = {
                    retrieved: incrementValue
                    analyzed: 0
                }
            else 
                totalStories.retrieved += incrementValue
            @trigger("addedStories:#{feed}")
        getTotal: (feed) ->
            @totalStoriesRetrieved[feed]


    class QueryRequest
        constructor: (@title) ->
            @totalStoriesRetrieved = new StoryRetrievalCounter

        fetchExistingQuery: ->
            $.getJSON("./queries/#{@title}", {}, ->)
        external_url: './externalNews'
        getNews: (feed) =>
            fns = {
                "google": @getGoogleNews
                "yahoo": @getYahooNews
                "feedzilla": @getFeedZillaNews
            }
            fns[feed].call(@)
        # desc: Issues a request to a curl script, retrieving google news stories
        # args: the query, the start index to search (0-56), and the done callback
        # rets: this
        getGoogleNews: (start, done = ->) ->
            query = @title
            start = start || 0
            $.getJSON(@external_url,
                source: 'google'
                q: query.toLowerCase()
                start: start 
                analyze: false
            , (responseStories) =>
                # console.log(responseStories)
                @totalStoriesRetrieved.addToTotal("google", responseStories.length)
                # Once google news is exhausted, execute callback 
                # if (start > 64 or !responseStories.length) and done? 
                # Get location data from OpenCalais for each story item
                stories.addToActiveSet(responseStories)
                # Otherwise, call self and keep going
                # if start < 64 then @getGoogleNews start + 8, done
                # else
                debugger
                # @totalStoriesRetrieved.trigger("retrieval_google:done") 
                # done()
            ).fail(=>   
                console.log(arguments)
            ).always =>
                @totalStoriesRetrieved.trigger("retrieval_google:done") 
                do done if done?
        getYahooNews: (start, done = ->) ->
            query = "\"#{@title.toLowerCase()}\""
            start || (start = 0)
            $.getJSON(@external_url,
                source: 'yahoo'
                q: query
                start: start
                analyze: false
            , (responseStories) =>
                if !responseStories?
                    @totalStoriesRetrieved.addToTotal("yahoo", responseStories?.length)
                    stories.addToActiveSet(responseStories)
                # get all news, including metadata
                total = 60 #news.totalresults
                # if start <= total then @getYahooNews start + 50, done
                # else 
                # @totalStoriesRetrieved.trigger("retrieval_yahoo:done") 
                # done()
                return @
            ).fail =>
                console.log(arguments);
            .always =>
                @totalStoriesRetrieved.trigger("retrieval_yahoo:done") 
                done()


        getFeedZillaNews: (done = ->) ->
            $.getJSON(@external_url, {
                q: @title
                source: 'feedzilla'
                analyze: false
            }, (responseStories) =>
                console.log(responseStories)
                @totalStoriesRetrieved.addToTotal("feedzilla", responseStories.length)
                stories.addToActiveSet(responseStories)
                # @totalStoriesRetrieved.trigger("retrieval_feedzilla:done") 
                debugger
            ).fail(=>
                console.log arguments
                # do done if done?
            ).always =>
                @totalStoriesRetrieved.trigger("retrieval_feedzilla:done") 
                done()
        doesExist: (done=->)-> 
            $.getJSON "./queryExists/#{@title}", {}, => done.apply(@, arguments);

    class Query extends Backbone.Model
        defaults: ->
            return {
                title: ""
                created: moment()
                stories: new stories.Stories()
            }
        initialize: ->
            @get("stories")?.query = @
        parse: (resp) ->
            resp.created = moment(resp.created);
            resp.last_query = moment(resp.last_query);
            if resp.stories? and resp.stories instanceof stories.Stories is false
                resp.stories = new stories.Stories(resp.stories, {parse: true})
            resp
        favorite: ->
            window.savedQueries?.add @
            query_id = @id || @get("id")
            $.post "./favorite", {
                query_id: query_id
                name: @get("title")
            }, (resp) =>
                try resp = JSON.parse(resp)
                if resp.id?
                    @id = resp.id
                    @set("id", resp.id);
    class Queries extends Backbone.Collection
        model: Query
        comparator: (m) -> -m.get("last_query");

    class EmptyQueryItem extends Marionette.ItemView
        template: "#empty-query-item"
        className: 'center'
        tagName: 'li'

    class QueryItem extends Marionette.ItemView
        template: "#query-item"
        tagName: "li"
        initialize: ->
            @listenTo @model, {
                "unfavorite": =>
                    @model.destroy()
                    @destroy()
            }

        events: 
            "click .js-load-map": ->
                window.destroyActiveModal =>
                    dispatcher.dispatch("navigate", "existing/#{@model.get("title")}", true)
            "click .js-remove-query": ->
                $.post("./unfavorite", {
                    id: @model.id
                }, (->) , 'json').success =>
                    @model.trigger("unfavorite");
                .error =>
                    swal({
                        type: "error"
                        title: "Error"
                        text: "Something went wrong deleting this story. Try again."
                        timer: 5000
                    })


    class QueryList extends Marionette.CollectionView
        childView: QueryItem
        emptyView: EmptyQueryItem
        tagName: 'ul'
        className: 'saved-queries-list'

    return {
        createRequest: (query) ->
            request = new QueryRequest(query)
        setActiveQuery: (query) ->
            _activeQuery = new Query(query, {parse: true});
        getActiveQuery: ->
            _activeQuery
        setSavedQueries: (queries) ->
            _savedQueries = new Queries(queries, {parse: true});
            _savedQueries.sort()
            _savedQueries
        getSavedQueriesList: ->
            list = new QueryList({collection: _savedQueries});
            list.render().el;
        getHelpString: -> _.template($("#query-list-help").html())()
        QueryAutoComplete: QueryAutoComplete
    }