require "cornerstone"
global.markdown = marked

# Store posts as JSON
# Also store posts as html
# Display Ace editor to edit markdown
# Stylesheet
# Header
# Navigation
# Manifest JSON
# Filetree

FiletreePresenter = require "./presenters/filetree"
Filetree = require "./filetree"

filetree = Filetree()

application = Model()

style = document.createElement "style"
style.innerHTML = require "./style"
document.head.appendChild style
document.body.appendChild require("./template")
  actions: require("./actions")()
  filetree: FiletreePresenter filetree, application

application.include require("./ace_shim")
