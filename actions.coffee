PostTemplate = require "./post_template"
Uploader = require "s3-uploader"
styl = require "styl"

module.exports = ->
  actions =
    preview: ->
    load: ->
      if name = prompt "Name"
        console.log name
        # Load the entry into the editor
    save: ->
      text = editor.getValue()
      html = markdown.toHTML text

      html = PostTemplate
        title: "TEST"
        html: html

      # Save the entry to S3
      policy = JSON.parse(localStorage.blogPolicy)
      uploader = Uploader(policy)

      # TODO: Update manifest
      # TODO: Uplod post JSON
      # TODO: Created At
      # TODO: Updated At
      # TODO: Author?

      if path = prompt "Path"
        # Upload post html
        uploader.upload
          key: path + ".html"
          blob: new Blob [html], type: "text/html"
          cacheControl: 600

    load_stylesheet: ->
      
    save_stylesheet: ->
      source = editor.getValue()

      style = styl(source, whitespace: true).toString()
      console.log style

  Object.keys(actions).map (name) ->
    name: name
    fn: actions[name]
