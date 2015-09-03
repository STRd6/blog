PostTemplate = require "./post_template"
Uploader = require "s3-uploader"
styl = require "styl"

module.exports = ->
  policy = JSON.parse(localStorage.blogPolicy)
  uploader = Uploader(policy)
  
  load = (path) ->
    deferred = Q.defer()

    xhr = new XMLHttpRequest()
    xhr.open('GET', "http://blog.whimsy.space/#{path}", true)

    xhr.onload = (e) ->
      if (200 <= this.status < 300) or this.status is 304
        deferred.resolve this.responseText
      else
        deferred.reject e
    xhr.onprogress = deferred.notify
    xhr.onerror = deferred.reject
    xhr.send()

    deferred.promise

  actions =
    preview: ->
      previewWindow = window.open null, "preview", "width=800,height=600"

      content = PostTemplate
        title: "TEST"
        html: markdown.toHTML """
          This is a test
          ========
          
          Yo
          
          Wat a cool test
        """

      previewWindow.document.open()
      previewWindow.document.write(content)
      previewWindow.document.close()

    load: ->
      if name = prompt "Name"
        console.log name
        # Load the entry into the editor
        load name + "?yolo"
        .then (content) ->
          editor.setValue(content)
          editor.getSession().setMode('markdown')

    save: ->
      text = editor.getValue()
      html = markdown.toHTML text

      html = PostTemplate
        title: "TEST"
        html: html

      # Save the entry to S3

      # TODO: Update manifest
      # TODO: Uplod post JSON
      # TODO: Created At
      # TODO: Updated At
      # TODO: Author?

      if path = prompt "Path"
        # Upload post html
        uploader.upload
          key: path + ".html"
          blob: new Blob [html], type: "text/html; charset=UTF-8"
          cacheControl: 60

        uploader.upload
          key: path + ".md"
          blob: new Blob [text], type: "text/markdown; charset=UTF-8"
          cacheControl: 0

    load_stylesheet: ->
      load("style.styl")
      .then (content) ->
        editor.setValue content
        editor.getSession().setMode('styl')

    save_stylesheet: ->
      source = editor.getValue()
      style = styl(source, whitespace: true).toString()

      uploader.upload
        key: "style.css"
        blob: new Blob [style], type: "text/css; charset=UTF-8"
        cacheControl: 0

      uploader.upload
        key: "style.styl"
        blob: new Blob [source], type: "text/styl; charset=UTF-8"
        cacheControl: 0

  Object.keys(actions).map (name) ->
    name: name
    fn: actions[name]
