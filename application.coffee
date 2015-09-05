Filetree = require "./filetree"
File = Filetree.File
HamletCompiler = require "./lib/hamlet-compiler"
styl = require "styl"
Uploader = require "s3-uploader"

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

compileTmpl = (source) ->
  fnTxt = HamletCompiler.compile source,
    compiler: CoffeeScript
    runtime: "require(\"/lib/hamlet-runtime\")"

  m = {}
  Function("module", "require", fnTxt)(m, require)
  tmpl = m.exports

  (data) ->
    tmpl(data).outerHTML

module.exports = (I={}, self=Model(I)) ->
  defaults I,
    posts: [{
      path: "hello"
      slug: "hello"
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
  self.attrModels "posts", File
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
        name: "Save"
        fn: ->
          self.publish()
      }]
    compileMarkdown: compileMarkdown
    publish: ->
      manifest =
        title: self.title()
        posts: self.posts()
        template: self.template()
        style: self.style()

      save "blog.json", JSON.stringify(manifest), "application/json"

      # Compile template
      templateContent = self.template().content()
      tmpl = compileTmpl(templateContent)

      # Save posts
      #  - TODO: Only if post or template changed
      #  - Save .htmls
      self.posts.forEach (post, i) ->
        path = post.I.slug
        md = post.content()

        html = tmpl extend
          post: post
        , self

        console.log html
        # save post.slug + ".html", html, "text/html"
        # .done()

    loadManifest: (path) ->
      load(path)
      .then ({posts, template, style}) ->
        posts.map (post) ->
          File post
        .concat [File style]
        .concat [File template]

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

  self.files = Observable.concat self.posts, self.template, self.style

  self.files.observe self.filetree().files
  self.filetree().files self.files()

  return self
