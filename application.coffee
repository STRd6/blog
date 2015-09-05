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

compileTmpl = (source) ->
  fnTxt = HamletCompiler.compile source,
    compiler: CoffeeScript
    runtime: "require(\"/lib/hamlet-runtime\")"

  m = {}
  Function("module", "require", fnTxt)(m, require)
  res = m.exports

  (content) ->
    c = document.createElement("content")
    c.innerHTML = content

    r = res
      content: c

    d = document.createElement "div"
    d.appendChild r

    return d.innerHTML

module.exports = (I={}, self=Model(I)) ->
  defaults I,
    filetree:
      files: [{
        path: "posts/hello.md"
        content: """
          Hello
          =====
          
          World
        """
      }, {
        path: "template.haml"
        content: """
          %html
            %head
              %meta(charset="UTF-8")
              %link(rel="stylesheet" type="text/css" href="style.css")

            %body
              = @content
        """
      }]

  policy = JSON.parse(localStorage.blogPolicy)
  uploader = Uploader(policy)

  save = (path, content, type, cacheControl=0) ->
    uploader.upload
      key: path
      blob: new Blob [content], type: type
      cacheControl: cacheControl

  posts = [{
    slug: "hello"
    content: """
      Hello
      =====
      
      World
    """
  }]

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
      # TODO: Save manifest

      # TODO: Save template sources
      # TODO: Save css

      # Compile template
      templateContent = self.filetree().files.last().content()
      tmpl = compileTmpl(templateContent)

      # Save posts
      #  - Save .mds
      #  - Save .htmls
      posts.forEach (post, i) ->
        path = post.slug
        md = post.content

        html = tmpl marked md

        save post.slug + ".md", md, "text/markdown"
        .done()
        save post.slug + ".html", html, "text/html"
        .done()

        # Update index.html
        # assumes first post is index
        if i is 0
          save "index.html", html, "text/html"
          .done()

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

  self
