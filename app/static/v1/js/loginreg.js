// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    $(".js-register").on("click", function() {
      return launchModal($(".js-register-panel").html(), {
        destroyHash: true
      });
    });
    return $(this).delegate(".js-register-submit", "click", function(e) {
      var $t, confirm, empty, form, name, pass;
      $t = $(this);
      form = $t.closest("form");
      name = function(attr) {
        return "[name=" + attr + "]";
      };
      pass = form.find(name("password")).val();
      confirm = form.find(name("confirm-password")).val();
      if (pass !== confirm) {
        alert("Your passwords don't match");
        e.preventDefault();
        return false;
      } else if (pass === "") {
        alert("You cannot have an empty password");
        e.preventDefault();
        return false;
      }
      empty = false;
      form.find("input").each(function() {
        if ($(this).val() === "") {
          return empty = true;
        }
      });
      if (empty) {
        e.preventDefault();
      }
      return true;
    });
  });

}).call(this);
