fs      = require 'fs'
path    = require 'path'
colors  = require 'colors'
proc    = require 'child_process'

mkdir = (path) ->
    fs.mkdir path, 0777, () ->
        console.log "    #{path}".grey

exec = (cmd) ->
    console.log "    #{cmd}".grey
    proc.exec cmd

cp = (src, dst) ->
    exec "cp #{src} #{dst}"

rmdir = (path) ->
    exec "rm -rf #{path}"

rm = (path) ->
    exec "rm -f #{path}"

task 'build', 'Build your boilerplate node server.', (options) ->
    console.log 'creating paths'.bold
    mkdir './static'
    mkdir './static/css'
    mkdir './static/js'
    mkdir './views'
    mkdir './models'
    mkdir './test'

    cp "./templates/app/server.coffee", "./server.coffee"
    cp "./templates/app/package.json", "./package.json"
    cp "./templates/app/.gitignore", "./.gitignore"
    cp "./templates/app/config.json", "./config.json"
    cp "./templates/app/Makefile", "./Makefile"
    cp "./templates/test/stub.coffee", "./test/stub.coffee"

    console.log 'downloading and extracting twitter bootstrap'.bold
    exec "curl http://twitter.github.com/bootstrap/assets/bootstrap.zip > ./static/bootstrap.zip"
    exec "unzip ./static/bootstrap.zip -d ./static"
    exec "cp -r ./static/bootstrap/* ./static"
    exec "rm -rf ./static/bootstrap ./static/bootstrap.zip"

    console.log 'copying jade templates and pesonal script templates'.bold
    cp "./templates/views/500.jade", "./views/500.jade"
    cp "./templates/views/404.jade", "./views/404.jade"
    cp "./templates/views/index.jade", "./views/index.jade"
    cp "./templates/views/layout.jade", "./views/layout.jade"
    cp "./templates/js/script.coffee", "./static/js/script.coffee"

    console.log 'setting up npm dependencies'.bold
    exec "npm install"

    console.log "removing the stuff you don't want".bold
    rmdir ".git"
    rmdir "templates"
    rm "README.md"

    console.log "reinitializing git".bold
    exec "git init"
    exec "git add ."
    exec 'git commit -m "Initial Boilerplate Commit"'
