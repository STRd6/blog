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

application = require("./application")()

style = document.createElement "style"
style.innerHTML = require "./style"
document.head.appendChild style
document.body.appendChild require("./template")(application)

application.include require("./ace_shim")
