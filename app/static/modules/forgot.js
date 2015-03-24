require.config({
    urlArgs: "bust=" + new Date().getTime(),
    paths: {
        "jquery"        : "dist/bower_components/jquery/dist/jquery.min",
        "sweetalert"    : "dist/bower_components/sweetalert/lib/sweet-alert"
    }
});

define(["jquery", "sweetalert"], function($, _, Backbone) {
    function submitPasswordChange(e) {
        var pass = $("[name='newpassword']").val()
        var confirm = $("[name='confirmpassword']").val()
        if (pass !== confirm) {
            swal({
                title: "Error!",  
                text: "Your passwords don't match!",  
                type: "error",   
                confirmButtonText: "OK",
                timer: 1700
            });
            e.preventDefault()
            return false
        }
        if (pass === "") {
            swal({
                title: "Error!",  
                text: "You need to enter a password!",  
                type: "error",   
                confirmButtonText: "OK",
                timer: 1700
            });
            e.preventDefault()
            return false
        }
        $.post("/resetPassword", {
            token: window.token.toString(),
            email: window.email,
            password: pass
        }, $.noop,'json').success(function(response) {
            if (response.updated === true) {
                swal({
                    type: 'success',
                    title: 'Updated Password',
                    text: 'You successfully updated your password.',
                    timer: 3000
                });
                setTimeout(function() { 
                    window.location.href = "./"
                }, 3000)
            }
        })
    }

    $(".js-submit").click(function(e) {
        submitPasswordChange(e);
    });
})