require "cornerstone"

File = (I={}, self=Model(I)) ->
  defaults I,
    content: ""

  self.attrObservable "content", "path"

  self

module.exports = Filetree = (I={}, self=Model(I)) ->
  defaults I,
    files: [{
      path: "test.md"
      content: "Radical\n=======\n\nDuuuuuder"
    }, {
      path: "wat.js"
      content: "alert('yolo')"
    }, {
      path: "test.css"
      content: """
        body {
          border: 8px solid green;
        }
      """
    }]

  self.attrModels "files", File

  self.extend
    sortedFiles: ->
      self.files().sort (a, b) ->
        if a.path() < b.path()
          -1
        else if a.path() >= b.path()
          1
        else
          0

  self

Filetree.File = File
