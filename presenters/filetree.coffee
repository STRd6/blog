module.exports = (filetree, application) ->
  extend {}, filetree,
    select: (file) ->
      unless session = file.session
        file.session = application.initSession(file)

      if file.post?()
        application.activePost file

      application.editor().getSession()?._signal("blur")
      application.editor().setSession(file.session)
      file.session._signal?("focus")
