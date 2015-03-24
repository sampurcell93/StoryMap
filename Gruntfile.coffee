module.exports = (grunt) =>

    grunt.initConfig
        # Works for now, but inefficient - compiles ALL coffee files each time one is saved
        coffee:
            dist:
                files: [{
                    expand: true
                    flatten: true
                    cwd: 'app/static/modules/src/'
                    src: ['*.coffee']
                    dest: 'app/static/modules/dist/'
                    rename: (dest, src) ->
                        dest + "/" + src.replace(/\.coffee$/, ".js")
                }]
        compass:
            dist:
                options:
                    sassDir: 'app/static/sass'
                    cssDir: 'app/static/stylesheets'
                    environment: 'production'
            dev:
                options:
                    sassDir: 'app/static/sass'
                    cssDir: 'app/static/stylesheets'
        # nodemon: 
        #     dev: 
        #         options: 
        #             file: 'app.js',
        #             nodeArgs: ['--debug'],
        #             env: 
        #                 PORT: '3000'
        watch:
          # node: 
          #   files: ['app.js']
          #   tasks: ["nodemon:dev"]
          sass:
            files: ["app/static/sass/*.scss"]
            tasks: ["compass:dist"]
          css:
            files: ["*.css"]
          coffee:
            files: ['app/static/modules/src/*.coffee']
            tasks: ['coffee:dist']
          livereload:
            files: ["app/static/stylesheets/*.css"]
            options:
              livereload: true

    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-compass'
    grunt.loadNpmTasks 'grunt-contrib-coffee'

    # grunt.registerTask 'server', (target) ->
    #   nodemon = grunt.util.spawn
    #       cmd: 'grunt'
    #         grunt: true
    #         args: 'nodemon'

    grunt.registerTask "default", ['watch']

