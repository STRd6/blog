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

Filetree = require "./filetree"

module.exports = (I={}, self=Model(I)) ->
  defaults I,
    filetree:
      files: [
        path: "yolo.txt"
        content: "duder"
      ]

  self.attrModel "filetree", Filetree

  self.extend
    actions: ->
      []
    publish: ->
      # Save manifest
      # Save template sources
      # Save css if changed
      # Save changed posts
      #  - Save .mds
      #  - Save .htmls
    
    loadManifest: (path) ->
      load(path)
      .then (result) ->
        console.log result

    newPost: ->
      
  self
