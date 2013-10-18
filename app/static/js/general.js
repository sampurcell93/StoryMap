// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    window.cc = function(arg) {
      return console.log(arg);
    };
    Number.prototype.monthToString = function() {
      var months;
      months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return months[this.valueOf()] || "Invalid";
    };
    Number.prototype.dayToString = function() {
      var days;
      days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      return days[this.valueOf()] || "Invalid";
    };
    Date.prototype.cleanFormat = function() {
      return this.getDate() + "/" + parseInt(this.getMonth() + 1) + "/" + this.getFullYear();
    };
    $(this).on("click switch", "[data-switch-icon]", function() {
      var $t, curricon, switchicon;
      $t = $(this);
      switchicon = $t.data("switch-icon");
      curricon = $t.attr("class").split(" ");
      _.each(curricon, function(classname) {
        if (classname.indexOf("icon") > -1) {
          curricon = classname;
          return false;
        }
      });
      $t.removeClass(curricon);
      $t.addClass(switchicon);
      return $t.data("switch-icon", curricon);
    });
    window.launchModal = function(content, options) {
      var defaults, modal;
      destroyModal(true);
      defaults = {
        close: true,
        destroyHash: false
      };
      options = _.extend(defaults, options);
      modal = $("<div />").addClass("modal");
      if ($.isArray(content)) {
        _.each(content, function(item) {
          return modal.append(item);
        });
      } else {
        modal.html(content);
      }
      if (options.close !== false) {
        modal.prepend("<i class='close-modal icon-untitled-7'></i>");
        modal.find(".close-modal").on("click", function() {
          $(document.body).removeClass("active-modal");
          modal.remove();
          if (options.destroyHash === true) {
            return window.location.hash = "";
          }
        });
      }
      $(document.body).addClass("active-modal").append(modal);
      return modal;
    };
    return window.destroyModal = function(existing) {
      return $(".modal").fadeOut("fast", function() {
        if (existing !== true) {
          return $(document.body).removeClass("active-modal");
        }
      });
    };
  });

}).call(this);
