// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var query;
    window.user = new window.models.User({
      id: window.userid
    });
    window.existingQueries = new window.collections.Queries();
    existingQueries._byTitle = {};
    window.mapObj = new window.GoogleMap;
    query = new models.Query;
    window.map = new views.MapItem({
      model: query
    });
    launchModal("<h2>loading....</h2>", {
      close: false
    });
    return user.fetch({
      success: function(model) {
        return existingQueries.fetch({
          success: function(coll) {
            destroyModal();
            query.user = user;
            _.each(coll.models, function(query) {
              return existingQueries._byTitle[query.get("title")] = query;
            });
            map.render();
            window.app = new window.Workspace({
              user: user,
              controller: map
            });
            return Backbone.history.start();
          }
        });
      }
    });
  });

}).call(this);
