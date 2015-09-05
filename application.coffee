Filetree = require "./filetree"
File = Filetree.File
HamletCompiler = require "./lib/hamlet-compiler"
styl = require "styl"
Uploader = require "s3-uploader"

Post = (I={}, self=File(I)) ->
  self.attrObservable "title", "slug"

  self.extend
    post: ->
      true

  self

module.exports = (I={}, self=Model(I)) ->
  defaults I,
    posts: [{
      title: "Welcome"
      path: "index"
      content: """
        Hello
        =====

        World
      """
    }]
    template:
      path: "_template"
      content: """
        %html
          %head
            %meta(charset="UTF-8")
            %link(rel="stylesheet" type="text/css" href="style.css")

          %body
            = @compileMarkdown @post.content()
      """
    style:
      path: "_style"
      content: """
        body
          margin: 0
      """
    filetree:
      files: []

  policy = JSON.parse(localStorage.blogPolicy)
  uploader = Uploader(policy)

  save = (path, content, type, cacheControl=0) ->
    uploader.upload
      key: path
      blob: new Blob [content], type: type
      cacheControl: cacheControl

  self.attrModel "filetree", Filetree
  self.attrModels "posts", Post
  self.attrModel "template", File
  self.attrModel "style", File
  self.attrObservable "title"

  self.extend
    actions: ->
      [{
        name: "New Post"
        fn: ->
          self.newPost()
      }, {
        name: "Preview"
        fn: ->
          self.preview()
      }, {
        name: "Load"
        fn: ->
          self.loadBlog()
      }, {
        name: "Save"
        fn: ->
          self.publish()
      }]

    compileMarkdown: compileMarkdown

    activePost: Observable()

    preview: ->
      previewWindow = window.open null, "preview", "width=800,height=600"

      post = self.activePost()
      tmpl = self.compileTemplate()
      html = tmpl extend
        post: post
      , self

      previewWindow.document.open()
      previewWindow.document.write(html)
      previewWindow.document.write """
        <style>
          #{self.compileStyle()}
        </style>
      """
      previewWindow.document.close()

    compileTemplate: ->
      compileTmpl(self.template().content())

    compileStyle: ->
      compileStyle(self.style().content())

    publish: ->
      manifest =
        title: self.title()
        posts: self.posts()
        template: self.template()
        style: self.style()

      save "blog.json", JSON.stringify(manifest), "application/json"

      # Compile template
      tmpl = self.compileTemplate()

      css = self.compileStyle()
      save "style.css", css, "text/css"

      # Save posts
      #  - TODO: Only if post or template changed
      #  - Save .htmls
      self.posts.forEach (post, i) ->
        path = post.I.slug
        md = post.content()

        html = tmpl extend
          post: post
        , self

        save post.path() + ".html", html, "text/html"
        .done()

    loadBlog: ->
      load("blog.json")
      .then (data) ->
        {posts, template, style} = JSON.parse data
        
        self.posts posts.map (post) ->
          Post post

        self.style File style
        self.template File template
      .done()

    newPost: ->
      title = prompt "Title"

      if title
        slug = title.replace(/[^a-zA-Z0-9]/g, '-').replace(/-+/g, '-')

        data =
          title: title
          path: slug
          content: ""

        self.posts.push Post data

  self.files = Observable.concat self.posts, self.template, self.style

  self.files.observe self.filetree().files
  self.filetree().files self.files()

  return self

## Helpers

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

compileMarkdown = (source) ->
  content = marked source

  post = document.createElement("post")
  post.innerHTML = content

  post

compileStyle = (source) ->
  styl(source, whitespace: true).toString()

compileTmpl = (source) ->
  fnTxt = HamletCompiler.compile source,
    compiler: CoffeeScript
    runtime: "require(\"/lib/hamlet-runtime\")"

  m = {}
  Function("module", "require", fnTxt)(m, require)
  tmpl = m.exports

  (data) ->
    tmpl(data).outerHTML
