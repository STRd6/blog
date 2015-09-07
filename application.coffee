Filetree = require "./filetree"
File = Filetree.File
HamletCompiler = require "./lib/hamlet-compiler"
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

    uploadAsset: (file) ->
      uploader.upload
        key: "assets/#{file.name}"
        blob: file
        cacheControl: 0

    preview: ->
      global.previewWindow = window.open null, "preview", "width=800,height=600"

      self.hotReload()

    hotReload: ->
      return unless global.previewWindow

      post = self.activePost()
      tmpl = self.compileTemplate()
      object = self.renderObject(post)
      html = tmpl object

      self.compileStyle().then (css) ->
        previewWindow.document.open()
        previewWindow.document.write(html)
        previewWindow.document.write """
          <style>
            #{css}
          </style>
        """
        previewWindow.document.close()

    compileTemplate: ->
      compileTmpl(self.template().content())

    compileStyle: ->
      compileStyle(self.style().content())

    uploadEditor: ->
      Require = require "require"
      editorJS = Require.executePackageWrapper(PACKAGE)
      
      remoteDepScripts = PACKAGE.remoteDependencies.map (url) ->
        "<script src=\"#{url}\"><\/script>"
      .join("\n")

      save "edit/index.html", """
        <html>
        <head>
          <meta charset="UTF-8">
          #{remoteDepScripts}
        </head>
        <body>
          <script>#{editorJS}<\/script>
        </body>
        </html>
      """, "text/html"

    helperMethods: ->
      compileMarkdown: compileMarkdown

    renderObject: (post) ->
      extend
        post: post.I
        posts: I.posts
      , self.helperMethods()

    publish: ->
      manifest =
        title: self.title()
        posts: self.posts()
        template: self.template()
        style: self.style()

      save "blog.json", JSON.stringify(manifest), "application/json"

      # Compile template
      tmpl = self.compileTemplate()

      self.compileStyle()
      .then (css) ->
        save "style.css", css, "text/css"
      .done()

      # Save posts
      #  - TODO: Only if post or template changed
      #  - Save .htmls
      self.posts.forEach (post, i) ->
        path = post.I.slug
        md = post.content()

        html = tmpl self.renderObject(post)

        save post.path(), html, "text/html"
        .done()

    loadBlog: ->
      load("blog.json")
      .then (data) ->
        {posts, template, style} = JSON.parse data
        
        self.posts posts.map (post) ->
          Post post

        self.style File style
        self.template File template
        
        self.filetree().files [
          self.template(),
          self.style()
          self.posts()...
        ]
      .done()

    newPost: ->
      title = prompt "Title"

      if title
        slug = title.replace(/[^a-zA-Z0-9]/g, '-').replace(/-+/g, '-').toLowerCase()

        data =
          title: title
          path: slug
          content: ""

        post = Post data
        self.posts.push post
        self.filetree().files.push post

  reloadPreview = ->
    try
      self.hotReload()
    catch e
      console.error e

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
  renderer = stylus(source)
  Q.npost(renderer, "render")

compileTmpl = (source) ->
  fnTxt = HamletCompiler.compile source,
    compiler: CoffeeScript
    runtime: "require(\"/lib/hamlet-runtime\")"

  m = {}
  Function("module", "require", fnTxt)(m, require)
  tmpl = m.exports

  (data) ->
    tmpl(data).outerHTML
