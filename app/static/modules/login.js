require.config({
    urlArgs: "bust=" + new Date().getTime(),
    paths: {
        "backbone"      : "dist/bower_components/backbone/backbone",
        "underscore"    : "dist/bower_components/underscore/underscore-min",
        "jquery"        : "dist/bower_components/jquery/dist/jquery.min",
        "marionette"    : "dist/bower_components/marionette/lib/backbone.marionette.min",
        "sweetalert"    : "dist/bower_components/sweetalert/lib/sweet-alert",
        "hub"           : "dist/hub",
        "modals"        : "dist/modal",
        "loaders"        : "dist/loaders",
        "stories"       : "dist/stories",
        "morphext"      : "dist/bower_components/Morphext/dist/morphext"
    }
});

define(["jquery", "underscore" ,"backbone", "marionette"], function($, _, Backbone, sweet) {

    require(["sweetalert", "morphext", "modals", "loaders"], function(sw, mx, Modal, loaders) {

        $("#mission-rotating").css("visibility", "visible").Morphext({
            // The [in] animation type. Refer to Animate.css for a list of available animations.
            animation: "bounceInUp",
            // An array of phrases to rotate are created based on this separator. Change it if you wish to separate the phrases differently (e.g. So Simple | Very Doge | Much Wow | Such Cool).
            separator: "|",
            // The delay between the changing of each phrase in milliseconds.
            speed: 7000
        });

        lFactory = new loaders()

        if ($(".error-flash").length > 0) {
            swal({
                title: "Error!",  
                text: $(".error-flash").text(),
                type: "error",   
                timer: 8000,
                confirmButtonText: "OK" 
            });
        }
        if ($(".success-flash").length > 0) {
            swal({
                title: "Registered!",  
                text: $(".success-flash").text(),
                type: "success",   
                timer: 8000,
                confirmButtonText: "OK" 
            });
        }

        function launchForgotPasswordDialog() {
            var m = new Modal({content: _.template($("#js-forgot-password").html())() })
            m.launch()
            m.$(".submit-email").click(function() {
                var email = $("#email-input").val();
                if (email === "") {
                    swal({
                        type: 'error',
                        title: 'Empty email.',
                        text: 'You need to enter an email address.',
                        timer: 2000
                    })
                }
                else {
                    var $t = $(this);
                    var spinner = $(lFactory.get("spinner"));
                    $t.append(spinner);
                    $.post("./forgot", {email: email}).success(function(response){
                        swal({
                            type: "success",
                            title: "Email sent.",
                            text: "We've sent you an email with a link to reset your password."
                        });
                        spinner.remove();
                    })
                }
            })
        }

        $(".js-register").on("click", function() {
            var m = new Modal({content: _.template($("#js-register-panel").html())(), destroyHash: true, escape: false})
            m.launch();
            m.$el.addClass("login-modal")
            m.$(".js-register-submit").on("click", function(e) {
                var $t = $(this);
                var form = $t.closest("form")
                var name = function(attr) {
                    return "[name=" + attr + "]"
                }
                var pass = form.find(name("password")).val()
                var confirm = form.find(name("confirm-password")).val()
                if (pass !== confirm) {
                    swal({
                        title: "Error!",  
                        text: "Your passwords don't match!",  
                        type: "error",   
                        confirmButtonText: "OK" 
                    });
                    e.preventDefault()
                    return false
                }
                if (pass === "") {
                    swal({
                        title: "Error!",  
                        text: "You need to enter a password!",  
                        type: "error",   
                        confirmButtonText: "OK" 
                    });
                    e.preventDefault()
                    return false
                }
                var empty = false
                form.find("input").each(function() {
                    if ($(this).val() === "") {
                        empty = true;
                        return false;
                    }
                })
                if (empty) {
                  e.preventDefault()  
                  return false;
                } 

                var $t = $(this);
                var spinner = $(lFactory.get("spinner"));
                $t.append(spinner);

                return true;
            });
        });

        $(".js-forgot-password").click(function() { 
            launchForgotPasswordDialog();
        })
    });
})