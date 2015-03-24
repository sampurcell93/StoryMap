(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define([], function() {
    var $overlay, $wrapper, Modal;
    $overlay = $(".modal-overlay");
    $wrapper = $(document.body);
    Modal = (function(_super) {
      __extends(Modal, _super);

      function Modal() {
        return Modal.__super__.constructor.apply(this, arguments);
      }

      Modal.prototype.className = 'modal';

      Modal.prototype.defaults = {
        xOffset: 0,
        yOffset: 0,
        isolate: false,
        close: true,
        destroyHash: false,
        destroyOthers: true,
        className: "",
        closeIn: null,
        escape: true,
        isUrl: false
      };

      Modal.prototype.initialize = function(options) {
        this.options = $.extend(this.defaults, options);
        return window.active_modal = this;
      };

      Modal.prototype.launch = function() {
        var content, modal, options;
        var that = this;
        if (this.$el.html()) {
          this.$el.appendTo($wrapper);
          return this;
        }
        options = this.options;
        content = options.content;
        modal = this.$el;
        if (options.destroyOthers !== false) {
          this.destroy();
        }
        try {
          if ($.isArray(content)) {
            $.each(content, function(index, item) {
              return modal.append(item);
            });
          } else if (options.isUrl) {
            $.get("templates/" + content + ".html", function(response) {
              return modal.html(response);
            });
          } else {
            modal.html(content);
          }
        } catch (_error) {}
        if (options.close !== false) {
          modal.prepend("<i class='close-modal icon-uni67'></i>");
          modal.find(".close-modal").on("click", function() {
            return that.destroy();
          });
          $wrapper.on("keydown.esc keyup.esc", (function(_this) {
            return function(e) {
              var key;
              key = e.keyCode || e.which;
              if (key === 27 && options.escape === true) {
                _this.destroy();
                return $wrapper.off("keydown.esc keyup.esc");
              }
            };
          })(this));
        }
        if (options.closeIn) {
          setTimeout((function(_this) {
            return function() {
              return _this.destroy();
            };
          })(this), options.closeIn);
        }
        $wrapper.addClass("active-modal").append(modal);
        if (options.isolate !== true) {
          $(".modal-overlay").fadeIn("fast");
        }
        this.renderOffset(options.xOffset, options.yOffset);
        modal.addClass(options.addClasses).attr("tabindex", 0).fadeIn("fast").focus();
        return this;
      };

      Modal.prototype.destroy = function(options, done) {
        var destroy_options;
        destroy_options = $.extend({
          destroyHash: false
        }, options);
        this.$el.fadeOut("fast", (function(_this) {
          return function() {
            _this.remove();
            if (done) {
              done()
            }
            return $overlay.fadeOut("fast");
          };
        })(this));
        $wrapper.removeClass("active-modal");
        return this;
      };

      Modal.prototype.renderOffset = function(x, y) {
        var current_x, current_y, el;
        if (x == null) {
          x = 0;
        }
        if (y == null) {
          y = 0;
        }
        el = this.$el;
        current_x = parseInt(el.css("left"));
        current_y = parseInt(el.css("top"));
        // this.$el.css({
        //   "left": current_x + x + "px",
        //   "top": current_y + y + "px"
        // });
        return this;
      };

      return Modal;

    })(Backbone.View);
    return Modal;
  });

window.destroyActiveModal = function(done) {
  if (this.active_modal) {
    console.log(this, done)
    this.active_modal.destroy({}, done)
  }
}

}).call(this);
