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
    }]

  self.attrModels "files", File

  self

Filetree.File = File
