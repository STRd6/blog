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

save = (path, content, type, cacheControl=0) ->
  uploader.upload
    key: path
    blob: new Blob [content], type: type
    cacheControl: cacheControl

HamletCompiler = require "./lib/hamlet-compiler"

compileTmpl = (source) ->
  fnTxt = HamletCompiler.compile source,
    compiler: CoffeeScript
    runtime: "require(\"/lib/hamlet-runtime\")"

  console.log fnTxt
  
  fnTxt

Filetree = require "./filetree"
File = Filetree.File

module.exports = (I={}, self=Model(I)) ->
  defaults I,
    filetree:
      files: [
        path: "template.haml"
        content: """
          %html
            %head
              %meta(charset="UTF-8")
              %link(rel="stylesheet" type="text/css" href="style.css")

            %body
              %content
                = @content
        """
      ]

  posts = []

  self.attrModel "filetree", Filetree

  self.extend
    actions: ->
      [{
        name: "New Post"
        fn: ->
          self.newPost()
      }, {
        name: "Save"
        fn: ->
          self.publish()
      }]
    publish: ->
      # Save manifest
      # Save template sources
      # Save css
      # Save posts
      #  - Save .mds
      #  - Save .htmls
      # Update index.html

      tmpl = compileTmpl(self.filetree().files.first())

    loadManifest: (path) ->
      load(path)
      .then (result) ->
        console.log result

    newPost: ->
      title = prompt "Title"

      if title
        slug = title.replace(/[^a-zA-Z0-9]/g, '-').replace(/-+/g, '-')

        data = 
          title: title
          slug: slug
          path: "posts/#{slug}.md"
          content: ""

        self.filetree().files.push File data

        posts.push data

  self
