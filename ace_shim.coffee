aceEditor = ace.edit "ace"
aceEditor.$blockScrolling = Infinity
aceEditor.setOptions
  fontSize: "16px"

module.exports = (I, self) ->
  modeFor = (extension) ->
    switch extension
      when "js"
        "javascript"
      when "md"
        "markdown"
      when "cson"
        "coffee"
      when ""
        "text"
      else
        extension

  extension = (path) ->
    if match = path.match(/\.([^\.]*)$/, '')
      match[1]
    else
      ''

  self.extend
    editor: ->
      aceEditor

    initSession: (file) ->
      session = ace.createEditSession(file.content())

      session.setMode("ace/mode/#{modeFor(extension(file.path()))}")

      session.setUseSoftTabs true
      session.setTabSize 2

      aceEditor.setOptions
        highlightActiveLine: true
        showPrintMargin: false

      # Filetree observable binding
      updating = false
      file.content.observe (newContent) ->
        return if updating

        session.setValue newContent

      # Bind session and file content
      session.on "change", ->
        updating = true
        file.content session.getValue()
        updating = false

      return session
